"""Recover main.py from notebooks that embed it as a base85 archive assigned to
a variable (often as many implicitly-concatenated string chunks)."""
import ast, base64, bz2, gzip, hashlib, io, json, lzma, pathlib, re, sys, tarfile, zlib

nb = json.loads(pathlib.Path(sys.argv[1]).read_text())
out = pathlib.Path(sys.argv[2])
cells = ["".join(c["source"]) for c in nb.get("cells", []) if c.get("cell_type") == "code"]
expected = None
for src in cells:
    m = re.search(r"EXPECTED_MAIN_SHA256\s*=\s*['\"]([0-9a-f]{64})", src)
    if m:
        expected = m.group(1)

payloads = []
for src in cells:
    try:
        tree = ast.parse(re.sub(r"^\s*%%\w+.*\n", "", src))
    except SyntaxError:
        continue
    for node in ast.walk(tree):
        if not isinstance(node, ast.Assign):
            continue
        try:
            val = ast.literal_eval(node.value)
        except Exception:
            continue
        if isinstance(val, str) and len(val) > 4000:
            payloads.append(val)

best = None
for p in payloads:
    clean = "".join(p.split())
    for dec in (base64.b85decode, base64.a85decode, base64.b64decode):
        try:
            raw = dec(clean.encode("ascii"))
        except Exception:
            continue
        for un in (lambda b: b, gzip.decompress, lzma.decompress, bz2.decompress, zlib.decompress):
            try:
                data = un(raw)
            except Exception:
                continue
            try:
                with tarfile.open(fileobj=io.BytesIO(data)) as tf:
                    for mem in tf.getmembers():
                        if mem.name.endswith("main.py"):
                            t = tf.extractfile(mem).read()
                            if b"def agent(" in t and (best is None or len(t) > len(best)):
                                best = t
            except Exception:
                if b"def agent(" in data and (best is None or len(data) > len(best)):
                    best = data
if best is None:
    print("NO_AGENT")
    sys.exit(1)
digest = hashlib.sha256(best).hexdigest()
ok = "sha OK" if expected and digest == expected else ("SHA MISMATCH!" if expected else "no published sha")
out.write_bytes(best)
nlines = best.count(chr(10).encode())
print("%s: %d bytes, %d lines, %s" % (out.name, len(best), nlines, ok))
