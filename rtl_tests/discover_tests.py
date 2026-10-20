import sys


def discover(module_name):
    mod = __import__(module_name)
    return vars(mod)["TOPMODEL"], vars(mod)["VERILOG_SOURCES"]


if __name__ == "__main__":
    module_name = sys.argv[1]
    toplevel, sources = discover(module_name)
    match sys.argv[2]:
        case "toplevel":
            print(toplevel)
        case "sources":
            print(sources)
        case _:
            raise ValueError(sys.argv[2])
