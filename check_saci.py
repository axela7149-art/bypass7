import hashlib, plistlib
from pathlib import Path
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

MAGIC = b'3105PATCH\0'
root = Path(r'C:\Users\Davi\Desktop\CLIENTES\BYPASS7-PROXY')
d = root / 'ThreeOneOSFive' / 'Resources' / 'OfficialPatches' / 'BYPASS7PROXY - HS SACI.3105'
data = d.read_bytes()
assert data.startswith(MAGIC)
env = plistlib.loads(data[len(MAGIC):])
pid = env['packageID'].upper()
print('pid', pid)
print('protected', env['isPasswordProtected'], 'schema', env['schemaVersion'], 'iters', env['kdfIterations'])

cands = [
    'G7#vQ9mZ2@rL8$xP4&kN6',
    'G7#vQ9!mZ2@rL8$xP4&kN6',
    'G7#vQ9mZ2@rL8\$xP4&kN6',
    'G7#vQ9!mZ2@rL8\$xP4&kN6',
]

for pw in cands:
    try:
        wrap = hashlib.pbkdf2_hmac('sha256', pw.encode('utf-8'), bytes(env['kdfSalt']), env['kdfIterations'], 32)
        kaad = ('3105PATCH/v{}/key/{}'.format(env.get('keyAADVersion') or env['schemaVersion'], pid)).encode()
        wb = bytes(env['wrappedContentKey'])
        ck = AESGCM(wrap).decrypt(wb[:12], wb[12:], kaad)
        if hashlib.sha256(ck).hexdigest().upper() == env['keyFingerprint'].hex().upper():
            paad = ('3105PATCH/v{}/payload/{}'.format(env['schemaVersion'], pid)).encode()
            ep = bytes(env['encryptedPayload'])
            plain = AESGCM(ck).decrypt(ep[:12], ep[12:], paad)
            proj = plistlib.loads(plain)['project']
            print('WORKS:', pw)
            print('name', repr(proj['name']))
            break
    except Exception as e:
        print('FAIL:', pw, type(e).__name__)