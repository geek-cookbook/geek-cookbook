# A script to add footers and check for dead links
import yaml
import os
import re
import sys
import pathlib
import difflib
import os.path


class LOG:
    FATAL = 0
    ERROR = 1
    WARN = 2
    INFO = 3
    DEBUG = 4


COLOR = True
LOGLEVEL = LOG.INFO


def log(severity, context, message):
    if severity > LOGLEVEL:
        return
    color = {
        LOG.FATAL: '\u001b[31m',
        LOG.ERROR: '\u001b[35m',
        LOG.WARN: '\u001b[33m',
        LOG.INFO: '\u001b[34m',
        LOG.DEBUG: '\u001b[37m'
    }[severity]
    seve = {
        LOG.FATAL: 'FATL',
        LOG.ERROR: 'EROR',
        LOG.WARN: 'WARN',
        LOG.INFO: 'INFO',
        LOG.DEBUG: 'DBUG'
    }[severity]

    if COLOR == False:
        print(f"{seve} {context}: {message}")
    else:
        print(f"\u001b[1m{color}{seve}\u001b[0m {context}: {message}")


class ContextFilters:

    def warn_unlinked(self, context):
        """Warns about any pages which have been created, but not put into the navigation"""
        for file in context['all_files']:
            if file in context['nav_files']:
                continue
            log(LOG.WARN, "warn_unlinked",
                f"{file} has been created, but not linked in nav")


class Filters:

    def warn_deadlink(self, content, context):
        """Checks for dead links between pages"""
        links = [link.replace(context['mkdocs']['site_url'], "") for _, link in re.findall(
            r"\[([\w\W]+?)\]\(([\w\W]+?)\)", content, re.MULTILINE) if ((link.startswith(
                "https://") or link.startswith("http://")) and link.startswith(context['mkdocs']['site_url']) or link.startswith("/") or "://" not in link) and "images" not in link]
        for l in links:
            link = l
            if l == '' or l == '/':
                link = "index.md"
            link = link.split("#")[0]

            path = context['docs_dir'] + link
            if not link.startswith("/"):
                path = os.path.join(
                    context['docs_dir'], os.path.dirname(context['file_name']), link)

            if not path.endswith(".md"):
                if path.endswith("/"):
                    path = path[:-1] + ".md"
                else:
                    path = path + ".md"

            abs_path = pathlib.Path(path).resolve()

            if not abs_path.exists():
                log(LOG.WARN, "warn_deadlink",
                    f"{context['file_name']} contains a dead link to {link} ({path})")

        return content

    # disabled for now because we're using snippets
    # def footer(self, content, context):
    #     """Appends a footer to the end of every manuscript file"""
    #     if not hasattr(self, "footer_content"):
    #         self.footer_path = os.path.join(
    #             os.path.dirname(__file__), "recipe-footer.md")
    #         footer_file = open(self.footer_path)
    #         self.footer_content = footer_file.read()
    #         self.footer_search = self.footer_content.split("\n")[
    #             0].replace("#", "")
    #         footer_file.close()
    #     if "index.md" in context['file_name']:
    #         log(LOG.DEBUG, "footer",
    #             f"ignoring {context['file_name']} as it contains index.md")
    #         return content

    #     if self.footer_search in content:
    #         log(LOG.WARN, "footer",
    #             f"Footer is hard-coded in {context['file_name']}")
    #         return content
    #     return content + "\n" + self.footer_content


def flattern(obj):
    resp = []

    if type(obj) == dict:
        for key, value in obj.items():
            if type(value) == dict or type(value) == list:
                resp.extend(flattern(value))
            else:
                resp.append(value)
    elif type(obj) == list:
        for value in obj:
            if type(value) == dict or type(value) == list:
                resp.extend(flattern(value))
            else:
                resp.append(value)
    return resp


def execute(dry_run, show_diffs, mkdocs_yaml):
    log(LOG.DEBUG, "", "Loading mkdocs.yml")
    mkdocs = yaml.load(open(mkdocs_yaml).read(), Loader=yaml.Loader)
    log(LOG.DEBUG, "mkdocs", mkdocs)
    log(LOG.DEBUG, "", "Loaded mkdocs.yml")

    log(LOG.DEBUG, "", "Registering filters")
    filters = [getattr(Filters(), func) for func in dir(
        Filters) if callable(getattr(Filters, func)) and not func.endswith("__")]
    for filter in filters:
        log(LOG.INFO, "Filter Info", f"{filter.__name__}: {filter.__doc__}")
    log(LOG.DEBUG, "", "Registered filters")

    log(LOG.DEBUG, "", "Registering context filters")
    context_filters = [getattr(ContextFilters(), func) for func in dir(
        ContextFilters) if callable(getattr(ContextFilters, func)) and not func.endswith("__")]

    for filter in context_filters:
        log(LOG.INFO, "Filter Info", f"{filter.__name__}: {filter.__doc__}")
    log(LOG.DEBUG, "", "Registered context filters")

    log(LOG.DEBUG, "", "Walking docs_dir for manuscript files")
    docs_dir = os.path.join(os.path.dirname(mkdocs_yaml), mkdocs['docs_dir'])
    all_files = flattern([[os.path.join(root, file).replace(docs_dir + "/", "") for file in files if file.endswith(".md")]
                          for root, dirs, files in os.walk(docs_dir)])
    log(LOG.DEBUG, "all_files", all_files)
    log(LOG.DEBUG, "", "Walked docs_dir")

    log(LOG.DEBUG, "", "Loading nav entries")
    nav_files = flattern(mkdocs['nav'])
    log(LOG.DEBUG, "nav_files", nav_files)
    log(LOG.DEBUG, "", "Loaded nav entries")

    log(LOG.DEBUG, "", "Constructing context")
    context = {
        'docs_dir': docs_dir,
        'all_files': all_files,
        'nav_files': nav_files,
        'mkdocs': mkdocs
    }
    log(LOG.DEBUG, "", "Constructed context")

    log(LOG.DEBUG, "", "Running context filters")
    for filter in context_filters:
        log(LOG.INFO, "Global", f"Running {filter.__name__}")
        filter(context)

    log(LOG.DEBUG, "", "Running filters per file")

    for file in all_files:
        log(LOG.INFO, "", f"Processing {file}")
        path = os.path.join(docs_dir, file)
        context['file_name'] = file
        file_open = open(path, 'r')
        original = file_open.read()
        content = original
        file_open.close()
        for filter in filters:
            log(LOG.DEBUG, file, f"Running \"{filter.__name__}\" filter")
            content = filter(content, context)
        if not dry_run:
            fo = open(path, 'w')
            fo.write(content)
            fo.close()

        if show_diffs:
            a = original
            b = content

            diffs = []
            diff_count = 0
            matcher = difflib.SequenceMatcher(None, a, b)
            for opcode, a0, a1, b0, b1 in matcher.get_opcodes():
                diff_count = diff_count + 1
                if opcode == "equal":
                    diff_count = diff_count - 1
                    diffs.append(a[a0:a1])
                elif opcode == "insert":
                    diffs.append("\u001b[42m" + b[b0:b1])
                elif opcode == "delete":
                    diffs.append("\u001b[41m" + a[a0:a1])
                elif opcode == "replace":
                    diffs.append("\u001b[42m" + b[b0:b1])
                    diffs.append("\u001b[41m" + a[a0:a1])
            if diff_count != 0:
                log(LOG.INFO, file, "\u001b[0m".join(diffs) + "\u001b[0m")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Stir up a cookbook")
    parser.add_argument(
        "mkdocs", help="Path to the mkdocs.yml file", type=str)
    parser.add_argument(
        "-d", "--dry", help="Run the build in dry mode (does not write changes)", action="store_true")
    parser.add_argument(
        "-i", "--diffs", help="Show diffs for changed files", action="store_true")

    args = parser.parse_args()

    execute(args.dry, args.diffs, args.mkdocs)


if __name__ == "__main__":
    main()
