return
  function (ms, m)
    local lib, err = loadfile(m .. '.lua')
    if not lib then
        return err
    end
    package.loaded[m] = lib()
    if not ms.ext then ms.ext = {} end
    ms.ext[m] = package.loaded[m]
    return 'successfully loaded ' .. m
  end
