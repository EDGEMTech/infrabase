
def base_set_filespath(path, d):
    filespath = []
    extrapaths = (d.getVar("FILESEXTRAPATHS") or "")

    # Remove default flag which was used for checking
    extrapaths = extrapaths.replace("__default:", "")
    
    # Don't prepend empty strings to the path list
    if extrapaths != "":
        path = extrapaths.split(":") + path
    
    # The ":" ensures we have an 'empty' override
    overrides = (":" + (d.getVar("FILESOVERRIDES") or "")).split(":")
    overrides.reverse()
    for o in overrides:
        for p in path:
            if p != "":
                filespath.append(os.path.join(p, o))
    return ":".join(filespath)

