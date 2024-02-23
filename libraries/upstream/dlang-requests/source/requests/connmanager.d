module requests.connmanager;

import std.typecons;
import std.datetime;
import std.array;
import std.algorithm;
import std.exception;

import std.experimental.logger;

import requests.streams;

import cachetools.cache;

/**
 * Keep opened connections for HTTP.
 * It is actually cache over tuple(schema, host, port) -> connection
 * with limited number of items.
 *
 * Evict least used.
*/
package struct ConnManager {
    package alias  CMKey = Tuple!(string, string, ushort);
    package struct CMValue {
        NetworkStream   stream;
        SysTime         timestamp;
    }
    private {
        CacheLRU!(CMKey, CMValue) __cache;
    }
    this(int limit) {
        __cache = new CacheLRU!(CMKey, CMValue);
        __cache.size = limit;
        __cache.enableCacheEvents();
    }
    ~this() {
        clear();
    }
    @property auto length() {
        return __cache.length;
    }
    ///
    /// put new stream in cache, evict old stream and return it.
    /// If nothing evicted return null. Returned(evicted) connection can be
    /// closed.
    ///
    NetworkStream put(string schema, string host, ushort port, NetworkStream stream)
    in { assert(stream !is null);}
    out{ assert(__cache.length>0);}
    do {
        NetworkStream e;
        CMKey     key = CMKey(schema, host, port);
        CMValue value = {stream: stream, timestamp: Clock.currTime};
        __cache.put(key, value);
        auto cacheEvents = __cache.cacheEvents();
        switch( cacheEvents.length )
        {
            case 0:
                return null;
            case 1:
                return cacheEvents.front.val.stream;
            default:
                assert(0);
        }
    }
    /**
        Lookup connection.
     */
    NetworkStream get(string schema, string host, ushort port)
    do
    {
        if ( __cache is null ) return null;
        auto v = __cache.get(CMKey(schema, host, port));
        if ( ! v.isNull() )
        {
            return v.get.stream;
        }
        return null;
    }

    /**
        Remove connection from cache (without close).
     */
    NetworkStream del(string schema, string host, ushort port) {
        NetworkStream s;
        CMKey key = CMKey(schema, host, port);
        __cache.remove(key);
        auto cacheEvents = __cache.cacheEvents();
        switch( cacheEvents.length )
        {
            case 0:
                return null;
            case 1:
                return cacheEvents.front.val.stream;
            default:
                assert(0);
        }
    }

    /**
        clear cache (and close connections)
     */
    void clear()
    out { assert(__cache is null || __cache.length == 0); }
    do  {
        if ( __cache is null ) return;

        __cache.clear();
        foreach(e; __cache.cacheEvents )
        {
            try
            {
                e.val.stream.close();
            }
            catch(Exception e)
            {
                debug(requests) tracef("%s while clear connmanager", e.msg);
            }
        }
        __cache = null;
    }
}

unittest {
    globalLogLevel = LogLevel.info;
    ConnManager cm = ConnManager(2);
    auto s0 = new TCPStream();
    auto s1 = new TCPStream();
    auto s2 = new TCPStream();

    auto e = cm.put("http", "s0", 1, s0);
    assert(e is null);
    assert(cm.get("http", "s0", 1) == s0);

    e = cm.put("http", "s1", 1, s1);
    assert(e is null);
    assert(cm.get("http", "s1", 1) == s1);

    e = cm.put("http", "s2", 1, s2);
    assert(e !is null);
    assert(cm.get("http", "s2", 1) == s2);
    assert(e == s0); // oldest
    e.close();

    // at this moment we have s1, s2
    // let try to update s1
    auto s3 = new TCPStream;
    e = cm.put("http", "s1", 1, s3);
    assert(e == s1);
    e.close();
    assert(cm.get("http", "s1", 1) == s3);

    cm.clear();
    assert(cm.get("http", "s1", 1) is null);
}
