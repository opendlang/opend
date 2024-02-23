module requests.pool;

import std.stdio;
import std.range;
import std.algorithm;
import std.concurrency;
import std.typecons;
import std.variant;
import std.random;
import std.string;
import std.format;
import core.thread;
import std.exception;
import std.experimental.logger;

import requests.request;
import requests.http;
import requests.base;
import requests.uri;
import requests.streams;

struct Job {
    enum Method {
        GET,
        POST,
    };

    package {
        string              _url;
        Method              _method = Method.GET;
        immutable(ubyte)[]  _data;                  // data for post
        immutable(ubyte)[]  _opaque;                // opaque data tie request and response
        uint                _maxRedirects = 10;
        Duration            _timeout = 30.seconds;
        immutable(string)[] _headers_h;
        immutable(string)[] _headers_v;
    }

    auto method(Method m) {
        _method = m;
        return this;
    }
    auto method(string m) {
        switch(m.toUpper()) {
            case "POST":
                _method = Method.POST;
                break;
            case "GET":
                _method = Method.GET;
                break;
            default:
                throw new Exception("Unknown method %s, known methods are GET,POST".format(m));
        }
        return this;
    }
    auto data(immutable(ubyte)[] d) {
        _data = d;
        return this;
    }
    auto maxRedirects(uint n) {
        _maxRedirects = n;
        return this;
    }
    auto timeout(Duration t) {
        _timeout = t;
        return this;
    }
    auto opaque(immutable(ubyte)[] o) {
        _opaque = o;
        return this;
    }
    auto addHeaders(in string[string] headers) {
        foreach(pair; headers.byKeyValue) {
            _headers_h ~= idup(pair.key);
            _headers_v ~= idup(pair.value);
        }
        return this;
    }
}

struct Result {
    enum {
        OK   = 1,
        QUIT = 2,
        EXCEPTION = 4
    }
    package {
        uint                _flags;
        ushort              _code;
        immutable(ubyte)[]  _data;       // response body
        immutable(ubyte)[]  _opaque;     // opaque data tie request and response
    }
    auto flags() pure @nogc {
        return _flags;
    }
    auto code() pure @nogc {
        return _code;
    }
    auto data() pure @nogc {
        return _data;
    }
    auto opaque() pure @nogc {
        return _opaque;
    }
}

struct Quit {
}

struct Route {
    string scheme;
    string host;
    ushort port;

    @disable this();

    this(string url) {
        URI parsed = URI(url);
        scheme = parsed.scheme;
        host = parsed.host;
        port = parsed.port;
    }
    bool opEquals(Route other) {
        bool r =  this.scheme == other.scheme
            && this.host == other.host
            && this.port == other.port;
        return r;
    }
    bool opEquals(ref Route other) {
        bool r = this.scheme == other.scheme
            && this.host == other.host
            && this.port == other.port;
        return r;
    }
}


void worker() {
    Request rq;
    bool    run = true;

    Result process(ref Job j) {
        debug(requests) tracef("Received job %s", j._url);

        rq.maxRedirects(j._maxRedirects);
        rq.timeout(j._timeout);
        rq.clearHeaders();
        if ( j._headers_h.length ) {
            auto headers = assocArray(zip(j._headers_h.dup, j._headers_v.dup));
            rq.addHeaders(headers);
        }
        Response rs;
        try {
            final switch(j._method) {
                case Job.Method.GET:
                    rs = rq.get(j._url);
                    break;
                case Job.Method.POST:
                    rs = rq.post(j._url, j._data);
                    break;
            }
            return Result(Result.OK, rs.code, assumeUnique(rs.responseBody.data), j._opaque);
        } catch (Exception e) {
            return Result(Result.EXCEPTION, 500, e.msg.representation(), j._opaque);
        }
    }

    try {
        while (run) {
            receive(
                (Tid p, Quit q) {
                    // cmd to quit
                    debug(requests) tracef("got quit");
                    run = false;
                },
                (Tid p, Job j) {
                    // cmd to process
                    debug(requests) tracef("got job");
                    auto r = process(j);
                    p.send(thisTid(), r);
                },
            );
        }
    }
    catch (OwnerTerminated e) {
        debug(requests) tracef("parent terminated");
    }
    catch (Exception e) {
        errorf("Exception ", e);
    }
    finally {
        debug(requests) tracef("worker done");
    }
}

class Manager(R) {
    R                   _range;     // input range
    uint                _workers;   // max num of workers
    Route[Tid]          _idle;      // idle workers with last route served
    Route[Tid]          _busy;      // busy workers with currently serving route
    Job[Tid]            _box;       // one-element queue
    size_t              _sent;
    size_t              _received;
    Nullable!Result     _result;
    uint                _rc;        // ref counter
    bool                _exhausted;

    bool boxIsEmpty(Tid t) {
        return _box[t] == Job.init;
    }

    auto findWorker(Route route) {
        foreach(t, ref r; _idle) {
            if ( r == route ) {
                // use it
                return t;
            }
        }
        foreach(t, ref r; _busy) {
            if ( r == route && _box[t] == Job.init ) {
                // use it
                return t;
            }
        }
        if ( _busy.length + _idle.length < _workers ) {
            return Tid.init;
        }
        return _idle.keys[0];
    }
}

struct Pool(R) {
private:
    Manager!R _m;
public:
    string toString() {
        return "Pool<>";
    }

   ~this() {
        _m._rc--;
        debug(requests) tracef("on ~ rc=%d", _m._rc);
        Tid me = thisTid();
        if ( _m._rc == 0 ) {
            foreach(ref t; _m._busy.keys ~ _m._idle.keys) {
                debug(requests) tracef("sending Quit message to workers");
                t.send(me, Quit());
            }
        }
    }

    this(R input_range, uint w) {
        _m = new Manager!R();
        _m._rc = 1;
        _m._range = input_range;
        _m._workers = w;
    }
    this(this) {
        assert( _m._rc > 0);
        _m._rc++;
        debug(requests) tracef("copy rc=%d", _m._rc);
    }

    bool empty() {
        debug(requests) tracef("input empty: %s, exhausted: %s, busy: %d", _m._range.empty(), _m._exhausted, _m._busy.length);
        if ( _m._range.empty() && _m._sent == 0 ) {
            // we didn't start processing and input already empty. Empty input range?
            return true;
        }
        return _m._exhausted;
    }
    /**
        popFront
    */
    void popFront()
    in
    {
        assert(_m._busy.length > 0 || _m._range.empty || _m._result.isNull);
        assert(_m._busy.length + _m._idle.length <= _m._workers);
    }
    do
    {
        auto owner = thisTid();
        Nullable!Tid  idle;
        bool result_ready = false;
        debug(requests) tracef("busy: %d, idle: %d, workers: %d", _m._busy.length, _m._idle.length, _m._workers);
        if ( _m._result.isNull ) {
            // case when popFront called without front
            front;
        }
        if ( _m._busy.length > 0 ) {
            receive(
                (Tid t, Result r) {
                    assert(t in _m._busy, "received response not from busy thread");
                    _m._received++;
                    _m._result = r;
                    result_ready = true;
                    if ( ! _m.boxIsEmpty(t) ) {
                        Job j = _m._box[t];
                        assert(Route(j._url) == _m._busy[t], "wrong route");
                        debug(requests) tracef("send job %s from the box", j._url);
                        // have job with the same route, worker is still busy
                        _m._box[t] = Job.init;
                        t.send(owner, j);
                        _m._sent++;
                    } else {
                        // move this thread from busy to idle threads
                        Route route = _m._busy[t];
                        debug(requests) tracef("release busy thread %s", route);
                        _m._busy.remove(t);
                        _m._idle[t] = route;
                        idle = t;
                    }
                }
            );
        }
        while( !_m._range.empty() && _m._busy.length < _m._workers) {
            debug(requests) trace("push next job to pool");
            Job j = _m._range.front();
            _m._range.popFront();
            Route route = Route(j._url);
            /*
            find best route.
            1. look up for idle worker that served same route.
            2. if 1. failed - look up for busy worker who server same route and have empty box
            3. if 1 and 2 failed - just use any idle worker ( we must have one anyay)
            */
            auto t = _m.findWorker(route);
            if ( t in _m._busy ) {
                // just place in box
                assert(_m._box[t] == Job.init);
                debug(requests) tracef("found best for %s in busy %s", route, _m._busy[t]);
                _m._box[t] = j;
                continue;
            } else
            if ( t in _m._idle ) {
                debug(requests) tracef("found best for %s in idle %s", route, _m._idle[t]);
                fromIdleToBusy(t, route);
            } else
            if ( !idle.isNull ) {
                debug(requests) tracef("use just released idle (prev job %s) for %s", _m._idle[t], route);
                t = idle.get;
                idle.nullify();
                fromIdleToBusy(t, route);
            } else {
                debug(requests) tracef("create worker for %s", route);
                t = spawn(&worker);
                _m._box[t] = Job.init;
                _m._busy[t] = route;
            }
            t.send(owner, j);
            _m._sent++;
        }
        debug(requests) tracef("input empty: %s, sent: %d, received: %d, busy: %d",
                                _m._range.empty, _m._sent, _m._received,_m._busy.length );
        if ( !result_ready && _m._range.empty && _m._sent == _m._received && _m._busy.length==0) {
            _m._exhausted = true;
        }
        else {
            _m._exhausted = false;
        }
    }
    /**
        front
    */
    Result front()
    out {
        assert(_m._busy.length > 0 || _m._range.empty);
    }
    do {
        if ( !_m._result.isNull ) {
            return _m._result.get;
        }
        Tid w;
        sendWhilePossible();
        receive(
            (Tid t, Result r) {
                debug(requests) trace("received first response");
                _m._result = r;
                // move this thread from busy to idle threads
                fromBusyToIdle(t);
                _m._received++;
                w = t;
            },
        );
        if ( !_m._range.empty && _m._busy.length == 0) {
            // when max number of workers = 1, then
            // at this point we will have only one idle worker,
            // and we need to have at least one busy worker
            // so that we can always read in popFront
            Job j = _m._range.front();
            Route route = Route(j._url);
            w.send(thisTid(), j);
            _m._range.popFront();
            fromIdleToBusy(w, route);
            _m._sent++;
        }
        return _m._result.get;
    }
    /**
        helpers
    */
    void fromBusyToIdle(Tid t) {
        assert(t in _m._busy);
        assert(t !in _m._idle);
        _m._idle[t] = _m._busy[t];
        _m._busy.remove(t);
    }
    void fromIdleToBusy(Tid t, Route r) {
        assert(t !in _m._busy);
        assert(t in _m._idle);
        _m._busy[t] = r;
        _m._box[t] = Job.init;
        _m._idle.remove(t);
    }
    void sendWhilePossible() {
        while( !_m._range.empty() && (_m._busy.length+_m._idle.length) < _m._workers) {
            Tid t = spawn(&worker);
            Job j = _m._range.front();
            Route route = Route(j._url);

            auto owner = thisTid();
            send(t, owner, j);
            _m._range.popFront();
            _m._busy[t] = route;
            _m._box[t] = Job.init;
            _m._sent++;
        }
    }
}

Pool!R pool(R)(R r, uint w) {
    enforce(w>0, "Number of workers must me > 0");
    return Pool!R(r, w);
}

version(None) unittest {

    version(vibeD) {
        string httpbinurl = "http://httpbin.org";
    } else {
        info("Testing pool");
        import httpbin;
        auto server = httpbinApp();
        server.start();
        scope(exit) {
            server.stop();
        }
        Thread.sleep(1.seconds);
        globalLogLevel = LogLevel.trace;
        string httpbinurl = "http://127.0.0.1:8081";
        Job[] jobs = [
            Job(httpbinurl ~ "/get").addHeaders([
                                "X-Header": "X-Value",
                                "Y-Header": "Y-Value"
                            ]),
            Job(httpbinurl ~ "/gzip"),
            Job(httpbinurl ~ "/deflate"),
            Job(httpbinurl ~ "/absolute-redirect/3")
                    .maxRedirects(2),
            Job(httpbinurl ~ "/range/1024"),
            Job(httpbinurl ~ "/post")
                    .method("POST")                     // change default GET to POST
                    .data("test".representation())      // attach data for POST
                    .opaque("id".representation),       // opaque data - you will receive the same in Result
            Job(httpbinurl ~ "/delay/3")
                    .timeout(1.seconds),                // set timeout to 1.seconds - this request will throw exception and fails
            Job(httpbinurl ~ "/stream/1024"),
        ];

        auto count = jobs.
            pool(6).
            filter!(r => r.code==200).
            count();

        assert(count == jobs.length - 2, "pool test failed");
        iota(20)
            .map!(n => Job(httpbinurl ~ "/post")
                            .data("%d".format(n).representation))
            .pool(10)
            .each!(r => assert(r.code==200));
        info("Testing pool - done");
    }
}
