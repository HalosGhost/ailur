return
  function (ms, m)
    local lib, err = loadfile(m .. '.lua')
    if not lib then
        return ('failed to load %s: %s'):format(m, err)
    end
    package.loaded[m] = lib()
    ms[m] = package.loaded[m]
    return ('successfully loaded %s. Tada!'):format(m)
  end
