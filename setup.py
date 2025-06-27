# Copyright (c) Crossbar.io Technologies GmbH. Licensed under Apache 2.0.

from setuptools import setup

with open('xbr/_version.py') as f:
    exec(f.read())  # defines __version__

with open('README.rst') as f:
    docstr = f.read()

# https://peps.python.org/pep-0440/#direct-references
# https://stackoverflow.com/a/63688209/884770
extras_require_xbr = [
    # bitarray is required by eth-account, but on pypy
    # see discussion/links on https://github.com/crossbario/autobahn-python/pull/1617
    'bitarray>=2.7.5',          # PSF
    # 'bitarray @ git+https://github.com/ilanschnell/bitarray.git@master#egg=bitarray',

    # CLI handling and color terminal output
    'click>=8.1.2',             # BSD license

    # the following is needed for XBR basics and XBR IDL code generation
    'cbor2>=5.2.0',             # MIT license
    'twisted>=20.3.0',          # MIT license

    # ImportError: cannot import name 'getargspec' from 'inspect'
    # https://github.com/ethereum/web3.py/issues/2704#issuecomment-1369041219
    # pip install git+https://github.com/ethereum/web3.py.git
    'web3[ipfs]>=6.0.0',        # MIT license

    # the following is needed for EIP712 ("signed typed data"):
    'rlp>=2.0.1',               # MIT license
    'py-eth-sig-utils>=0.4.0',  # MIT license (https://github.com/rmeissner/py-eth-sig-utils)
    'py-ecc>=5.1.0',            # MIT license (https://github.com/ethereum/py_ecc)

    'eth-abi>=4.0.0',           # MIT license (https://github.com/ethereum/eth-abi)

    # the following is needed (at least) for BIP32/39 mnemonic processing
    'mnemonic>=0.19',           # MIT license (https://github.com/trezor/python-mnemonic)
    'base58>=2.1.0',            # MIT license (https://github.com/keis/base58)
    'ecdsa>=0.16.1',            # MIT license (https://github.com/warner/python-ecdsa)
    'py-multihash>=2.0.1',      # MIT license (https://github.com/multiformats/py-multihash / https://pypi.org/project/py-multihash/)

    # the following is needed for the WAMP/XBR IDL code generator
    'jinja2>=2.11.3',           # BSD license
    'yapf==0.29.0',             # Apache 2.0

    # the following is needed for XBR account synch and device pairing
    'spake2>=0.8',              # MIT license (https://github.com/warner/python-spake2/blob/master/LICENSE)
    'hkdf>=0.0.3',              # BSD 2-Clause "Simplified" License
]

# required for UI based tools, e.g. xbrnetwork-ui (autobahn.xbr._gui:_main)
extras_require_ui = [
    # the following is needed for the graphical XBR onboarding UI
    #
    # On PyPy, even pygobject-3.52.3 does not work, because they use a pythoncapi-compat which is too old1
    #
    # See:
    #   - https://github.com/pypy/pypy/issues/5248
    #   - https://gitlab.gnome.org/GNOME/pygobject/-/issues/684
    #
    # This was fixed here:
    #   - https://gitlab.gnome.org/GNOME/pygobject/-/merge_requests/419
    #
    # IMPORTANT: because of above, you will need to
    #
    #  pip3 install git+https://gitlab.gnome.org/GNOME/pygobject
    #
    # FIXME: reactivate here once pygobject-3.52.4 is released!
    #
    # 'PyGObject>=3.52.4',        # GNU Lesser General Public License v2 or later (LGPLv2+) (GNU LGPL)
]

xbr_packages = [
    'autobahn.xbr',
    'autobahn.xbr.test',
    'autobahn.asyncio.xbr',
    'autobahn.twisted.xbr',
]

if 'AUTOBAHN_STRIP_XBR' in os.environ:
    # force regeneration of egg-info manifest for stripped install
    shutil.rmtree('autobahn.egg-info', ignore_errors=True)
else:
    extras_require_all += extras_require_xbr
    packages += xbr_packages
    package_data['xbr'] = [
        './xbr/templates/py-autobahn/*.py.jinja2',
        './xbr/templates/sol-eip712/*.sol.jinja2',
    ]
    entry_points['console_scripts'] += ["xbrnetwork = autobahn.xbr._cli:_main"]
    entry_points['console_scripts'] += ["xbrnetwork-ui = autobahn.xbr._gui:_main"]

extras_require={
    'xbr': extras_require_xbr,
    'ui': extras_require_ui,
},

setup(
    name='xbr',
    version=__version__,
    description='XBR smart contracts and ABIs',
    long_description=docstr,
    license='Apache 2.0 License',
    author='Crossbar.io Technologies GmbH',
    author_email='autobahnws@googlegroups.com',
    url='https://github.com/crossbario/xbr-protocol',
    platforms=('Any'),
    python_requires='>=3.7',
    packages=['xbr'],

    # this flag will make files from MANIFEST.in go into _source_ distributions only
    include_package_data=True,

    # in addition, the following will make the specified files go into
    # source _and_ bdist distributions! For the LICENSE file
    # specifically, see setup.cfg
    # data_files=[('.', ['list', 'of', 'files'])],

    # this package does not access its own source code or data files
    # as normal operating system files
    zip_safe=True,

    # http://pypi.python.org/pypi?%3Aaction=list_classifiers
    classifiers=[
        "License :: OSI Approved :: Apache Software License",
        "Development Status :: 4 - Beta",
        "Environment :: Console",
        "Intended Audience :: Developers",
        "Operating System :: OS Independent",
        "Programming Language :: Python",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.7",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: Implementation :: CPython",
        "Programming Language :: Python :: Implementation :: PyPy",
        "Topic :: Software Development :: Libraries",
        "Topic :: Software Development :: Libraries :: Application Frameworks",
    ],
    keywords='autobahn crossbar wamp xbr ethereum abi',
)
