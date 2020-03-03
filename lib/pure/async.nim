when defined(js):
    import asyncjs
    export asyncjs
else:
    import asyncmacro, asyncfutures
    export asyncmacro, asyncfutures
