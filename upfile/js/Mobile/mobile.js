var ASDHT = window.ASDHT || {};
ASDHT.namespace = function () {
    var b = arguments, g = null, e, c, f;
    for (e = 0; e < b.length; ++e) {
        f = b[e].split(".");
        g = ASDHT;
        for (c = (f[0] === "ASDHT") ? 1 : 0; c < f.length; ++c) {
            g[f[c]] = g[f[c]] || {};
            g = g[f[c]]
        }
    }
    return g
};
ASDHT.namespace("touch");
(function (a) {
    ASDHT.touch = {
        imginit: function () {
            a("img").unveil();
        },
        goTop: function () {
            var b = a("#nav-top");
            b && b.on('click', function (a) {
                window.scrollTo(0, 0);
            })
        }
    };
})(Zepto);
$(document).ready(function () {
    ASDHT.touch.imginit();
    ASDHT.touch.goTop();
});