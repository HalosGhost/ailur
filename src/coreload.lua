return
  function (ms, m)
    package.loaded[m] = nil
    ms[m] = require(m)
  end
