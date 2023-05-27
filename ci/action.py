import os, subprocess

def main():
    git_log_cmd = """git log --format="%H" -n 1"""
    koch_boot_cmd = """./koch boot --gc:orc -d:release"""
    result = "Thanks for your hard work on this PR!\nThe lines below are statistics of the Nim compiler built from "
    commit_hash = subprocess.run(git_log_cmd, shell=True, check=True, capture_output=True, encoding="utf8").stdout.strip().lower()
    result += f"{commit_hash}\n"
    koch_output = subprocess.run(koch_boot_cmd, shell=True, check=True, capture_output=True, encoding="utf8").stdout.strip().lower().splitlines()[::-1]
    for index, line in enumerate(koch_output):
        if line.strip().startswith("hint: mm: orc;"):
            result += f"{line}\n"                                     # Line with "hint: mm: orc;""
            statistics = koch_output[index - 1].split("proj:", 1)[0]  # Line with "N lines; Ns; NMiB peakmem;"
            result += f"{statistics}\n"
            break
    os.makedirs("ci/nimcache", exist_ok=True)
    with open("ci/nimcache/results.txt", "w") as output_file:
        output_file.write(result)

if __name__ == "__main__":
    main()
