module https;

import requests;
import std.experimental.logger;

version(vibeD) {
}
else {
    unittest {
        globalLogLevel(LogLevel.info);
        auto rq = Request();
        rq.keepAlive = false;
        info("Testing https using google.com");
        auto rs = rq.get("https://google.com");
        assert(rs.responseBody.length > 0);
    }
}

version(unittest_fakemain) {
void main () {}
}
