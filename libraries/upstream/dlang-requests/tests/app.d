import httpbin;
import requests;
import std.experimental.logger;

version(vibeD) {
}
else {
    unittest {
        globalLogLevel(LogLevel.info);
        auto s = httpbinApp();
        scope (exit) {
            s.stop();
        }
        s.start();
        auto rq = Request();
        rq.keepAlive = false;
        auto rs = rq.get("http://127.0.0.1:8081/get");
        assert(rs.code == 200);
    }
}

version(unittest_fakemain) {
void main () {}
}
