.PHONY: list coverage docs clean build test

TRUFFLE = ${PWD}/node_modules/.bin/truffle
SOLHINT = ${PWD}/node_modules/solhint/solhint.js
COVERAGE = ${PWD}/node_modules/.bin/solidity-coverage

SCOUR = scour
SCOUR_FLAGS = --remove-descriptive-elements --enable-comment-stripping --enable-viewboxing --indent=none --no-line-breaks --shorten-ids

AWS_DEFAULT_REGION = eu-central-1
AWS_S3_BUCKET_NAME = xbr.foundation

XBRNETWORK=${HOME}/.local/bin/xbrnetwork

test_mnemonic:
	# python -m pytest -rsx autobahn/xbr/test/test_mnemonic.py
	USE_TWISTED=1 trial autobahn.xbr.test

clean_catalog:
	cd ./autobahn/xbr/test/catalog && make clean

rebuild_catalog:
	cd ./autobahn/xbr/test/catalog && make distclean && make build


default:
	@echo 'Targets:'
	@echo
	@echo '   clean                  '
	@echo '   clean_all              '
	@echo '   clean_docs             '
	@echo ' * clean_ganache          '
	@echo '   clean_images           '
	@echo
	@echo ' * install                '
	@echo '   update_dependencies    '
	@echo
	@echo ' * run_ganache            '
	@echo
	@echo '   compile                '
	@echo '   lint                   '
	@echo ' * test                   '
	@echo '   coverage               '
	@echo ' * deploy                 '
	@echo '   deploy_ropsten         '
	@echo '   deploy_ropsten_dryrun  '
	@echo
	@echo '   docs                   '
	@echo '   run_docs               '
	@echo '   images                 '
	@echo '   check_docs             '
	@echo '   spellcheck_docs        '
	@echo '   publish_docs           '
	@echo
	@echo '   publish_ipfs_eula      '
	@echo '   publish_ipfs_members   '
	@echo
	@echo '   truffle_build          '
	@echo '   truffle_compile        '
	@echo '   truffle_test           '
	@echo
	$(TRUFFLE) version
	$(SOLHINT) version
	$(SCOUR) --version

list_targets:
	@grep '^[^#[:space:]].*:' Makefile

clean: clean_docs
	-rm -rf ./abi/
	-rm -rf ./build/
	-rm -rf ./dist/
	-rm -rf ./*.egg-info/
	-rm -rf ./.tox/
	-rm -rf ./coverage
	-rm -rf ./coverageEnv
	-rm -f ./coverage.json
	-rm -f ./npm-debug.log
	-rm -f ./scTopics
	-rm -f ./*.pid
	-find . -name "__pycache__" -type d -exec rm -rf {} \;

clean_all: clean_docs clean
	-rm -rf ./node_modules/
	-rm -f ./package-lock.json


install:
	pip install -r requirements.txt
	npm install --only=dev
	npm outdated
	@echo "run 'ncu -u' to update deps .."
	$(TRUFFLE) version
	$(SOLHINT) version

update_dependencies:
	npm i -g npm-check-updates
	ncu -u
	npm install

# https://www.npmjs.com/package/truffle-flattener
# https://github.com/nomiclabs/truffle-flattener
flatten:
	./node_modules/.bin/truffle-flattener ./contracts/XBRToken.sol > ./build/contracts/XBRTokenFlattened.sol
	sed -i '/^\/\/ SPDX/d' ./build/contracts/XBRTokenFlattened.sol

	./node_modules/.bin/truffle-flattener ./contracts/XBRNetwork.sol > ./build/contracts/XBRNetworkFlattened.sol
	sed -i '/^\/\/ SPDX/d' ./build/contracts/XBRNetworkFlattened.sol

lint:
	$(SOLHINT) "contracts/**/*.sol"

test:
	$(TRUFFLE) test --network ganache

test_01:
	$(TRUFFLE) test --network ganache ./test/01_token.js

test_02:
	$(TRUFFLE) test --network ganache ./test/02_member.js

test_03:
	$(TRUFFLE) test --network ganache ./test/03_market.js

test_04:
	$(TRUFFLE) test --network ganache ./test/04_channel.js

test_05:
	$(TRUFFLE) test --network ganache ./test/05_domain.js

test_06:
	$(TRUFFLE) test --network ganache ./test/06_catalog.js

test_07:
	$(TRUFFLE) test --network ganache ./test/07_test.js


coverage:
	truffle run coverage


compile_dist:
	-rm ./build/contracts/*.json
	$(TRUFFLE) compile --all
	python ./check-abi-files.py
	-rm ../../crossbario/autobahn-python/autobahn/xbr/contracts/*.json
	cp -r ./build/contracts/*.json ../../crossbario/autobahn-python/autobahn/xbr/contracts/
	-rm ../../crossbario/autobahn-js/packages/autobahn-xbr/lib/contracts/*.json
	cp -r ./build/contracts/*.json ../../crossbario/autobahn-js/packages/autobahn-xbr/lib/contracts/

deploy:
	@echo
	@python ./check-abi-files.py
	@echo
	@$(TRUFFLE) migrate --reset --network ganache

deploy_ropsten_dryrun:
	$(TRUFFLE) migrate --reset --network ropsten --dry-run

deploy_ropsten:
	$(TRUFFLE) migrate --reset --network ropsten

deploy_rinkeby_dryrun:
	$(TRUFFLE) migrate --reset --network rinkeby --dry-run

deploy_rinkeby:
	$(TRUFFLE) migrate --reset --network rinkeby

# https://kalis.me/verify-truffle-smart-contracts-etherscan/
verify_etherscan_1:
	-$(TRUFFLE) run verify XBRToken --network rinkeby
	-$(TRUFFLE) run verify XBRNetwork --network rinkeby
	-$(TRUFFLE) run verify XBRCatalog --network rinkeby
	-$(TRUFFLE) run verify XBRDomain --network rinkeby
	-$(TRUFFLE) run verify XBRMarket --network rinkeby
	-$(TRUFFLE) run verify XBRChannel --network rinkeby

verify_etherscan_2:
	-npx truffle run verify --network rinkeby XBRToken
	-npx truffle run verify --network rinkeby XBRNetwork
	-npx truffle run verify --network rinkeby XBRCatalog
	-npx truffle run verify --network rinkeby XBRDomain
	-npx truffle run verify --network rinkeby XBRMarket
	-npx truffle run verify --network rinkeby XBRChannel

#
# Truffle in Docker
#
truffle_build:
	# docker-compose build --no-cache truffle
	docker-compose build truffle

truffle_compile:
	docker run -it --rm --volume=${PWD}:/code:rw crossbario/truffle
	# docker run -it --rm -v${PWD}:/code --network host --entrypoint /bin/bash crossbario/truffle

truffle_test:
	docker run -it --rm --volume=${PWD}:/code:rw --network=host crossbario/truffle test --network ganache


#
# XBR v20.5.1 "EULA": QmUEM5UuSUMeET2Zo8YQtDMK74Fr2SJGEyTokSYzT3uD94
#
publish_eula:
	curl "https://ipfs.infura.io:5001/api/v0/add?pin=false" \
		-X POST \
		-H "Content-Type: multipart/form-data" \
		-F file=@"EULA"

fetch_eula:
	curl "https://ipfs.infura.io:5001/api/v0/cat?arg=QmUEM5UuSUMeET2Zo8YQtDMK74Fr2SJGEyTokSYzT3uD94"

#
# Crossbar.io FX v20.5.1 "LICENSE": QmZSrrVWh6pCxzKcWLJMA2jg3Q3tx4RMvg1eMdVSwjmRug
#
publish_cfx_license:
	curl "https://ipfs.infura.io:5001/api/v0/add?pin=false" \
		-X POST \
		-H "Content-Type: multipart/form-data" \
		-F file=@"../crossbarfx/crossbarfx/LICENSE"

fetch_cfx_license:
	curl "https://ipfs.infura.io:5001/api/v0/cat?arg=QmZSrrVWh6pCxzKcWLJMA2jg3Q3tx4RMvg1eMdVSwjmRug"


publish_cfx_test_config:
	curl "https://ipfs.infura.io:5001/api/v0/add?pin=false" \
		-X POST \
		-H "Content-Type: multipart/form-data" \
		-F file=@"../crossbar-examples/nodeinfo/.crossbar/config.json"

fetch_cfx_test_config:
	curl "https://ipfs.infura.io:5001/api/v0/cat?arg=QmQ5JFWUMNhDGLigbqzWkJxJiB3mKRgT8L99pq7tx6ypKW"


#
# Ganache test blockchain as docker container "xbr-protocol_ganache_1"
#

# The following is for building our development blockchain docker image, which is
# Ganache + deployed XBR smart contracts + initial balances for testaccounts (both ETH and XBR).
#
# The XBR contracts are deployed using a different seedphrase than the test accounts
# which are initialized with some ETH+XBR balance!
#
# The deploying onwer is derived from a seedphrase read from an env var:
#
# 	export XBR_HDWALLET_SEED="myth like bonus scare over problem client lizard pioneer submit female collect"
#
# and results in contract addresses:
#
# 	export XBR_DEBUG_TOKEN_ADDR=0x254dffcd3277C0b1660F6d42EFbB754edaBAbC2B
# 	export XBR_DEBUG_NETWORK_ADDR=0xC89Ce4735882C9F0f0FE26686c53074E09B0D550
#
# public: 	https://hub.docker.com/r/crossbario/crossbarfx-blockchain
# admin:  	https://hub.docker.com/repository/docker/crossbario/crossbarfx-blockchain

# 1) clean file staging area to create blockchain docker image
clean_ganache:
	-rm -rf ./docker/data/
	mkdir ./docker/data/

# 2) run a blockchain from the empty staging area
run_ganache:
	# sudo chown -R 1000:1000 docker/data/
	docker-compose up --force-recreate ganache

# 3) compile xbr smart contracts
compile:
	wc -l contracts/*.sol
	cloc contracts/*.sol
	grep "struct [A-Z][A-Za-z0-9]* {" contracts/XBRTypes.sol | sort
	$(TRUFFLE) compile --all
	python ./check-abi-files.py

# 4) deploy xbr smart contract to blockchain
deploy_ganache:
	python ./check-abi-files.py
	$(TRUFFLE) migrate --reset --network ganache

# 5) initialize blockchain data
init_ganache:
	python docker/init-blockchain.py --gateway http://localhost:1545

# 6) build a blockchain (ganache based) docker image using the initialized data from the staging area
build_ganache_docker:
	cd docker && \
	docker build \
		-t crossbario/crossbarfx-blockchain:${XBR_PROTOCOL_VERSION} \
		-t crossbario/crossbarfx-blockchain:latest \
		-f Dockerfile.ganache \
		.

# 7) publish locally created docker image with xbr-preinitialized ganache blockchain
publish_ganache_docker:
	docker push crossbario/crossbarfx-blockchain:${XBR_PROTOCOL_VERSION}
	docker push crossbario/crossbarfx-blockchain:latest

###########

# run the built "ganache with XBR" image
run_ganache_docker:
	# sudo chown -R 1000:1000 docker/data/
	docker-compose up --force-recreate ganache_xbr

# show balances of ETH and XBR on test accounts in ganache
check_ganache:
	python docker/init-blockchain.py --showonly --gateway http://localhost:1545

# check ABI Files
check_abi_files:
	python ./check-abi-files.py

#
# build optimized SVG files from source SVGs
#
BUILDDIR = docs/_static/gen

# build "docs/_static/gen/*.svg" optimized SVGs from "docs/_graphics/*.svg" using Scour
# note: this currently does not recurse into subdirs! place all SVGs flat into source folder
SOURCEDIR = docs/_static/drawing

SOURCES = $(wildcard $(SOURCEDIR)/*.svg)
OBJECTS = $(patsubst $(SOURCEDIR)/%.svg, $(BUILDDIR)/%.svg, $(SOURCES))

$(BUILDDIR)_exists:
	mkdir -p $(BUILDDIR)

images: $(BUILDDIR)_exists $(BUILDDIR)/$(OBJECTS)
	@echo "optimizing images:\n"$(SOURCES)

$(BUILDDIR)/%.svg: $(SOURCEDIR)/%.svg
	$(SCOUR) $(SCOUR_FLAGS) $< $@

clean_images:
	-rm -rf docs/_static/gen


#
# XBR Protocol documentation
#
docs:
	cd docs && sphinx-build -b html . _build

check_docs:
	cd docs && sphinx-build -nWT -b dummy . _build

spellcheck_docs:
	cd docs && sphinx-build -nWT -b spelling \
		-d ./_build/doctrees . ./_build/spelling

run_docs: docs
	twistd --nodaemon web --path=docs/_build --listen=tcp:8090

# build and deploy latest docs:
#   => https://s3.eu-central-1.amazonaws.com/xbr.foundation/docs/protocol/index.html
#   => https://xbr.network/docs/protocol/index.html
publish_docs:
	aws s3 cp --recursive --acl public-read \
		./docs/_build s3://$(AWS_S3_BUCKET_NAME)/docs/protocol

clean_docs:
	-rm -rf docs/_build

# build Python XBR contracts/ABI package
build_python: compile
	python setup.py sdist bdist_wheel

# publish Python XBR contracts/ABI package to crossbarbuilder
upload_python: build_python
	ls -la dist
	aws s3 rm s3://crossbarbuilder/wheels/xbr-${XBR_PROTOCOL_VERSION}-py2.py3-none-any.whl
	aws s3 rm s3://crossbarbuilder/wheels/xbr-latest-py2.py3-none-any.whl
	aws s3 cp --acl public-read ./dist/xbr-${XBR_PROTOCOL_VERSION}-py2.py3-none-any.whl s3://crossbarbuilder/wheels/xbr-${XBR_PROTOCOL_VERSION}-py2.py3-none-any.whl
	aws s3 cp --acl public-read ./dist/xbr-${XBR_PROTOCOL_VERSION}-py2.py3-none-any.whl s3://crossbarbuilder/wheels/xbr-latest-py2.py3-none-any.whl
	aws s3 ls crossbarbuilder/wheels/xbr-

# publish Python XBR contracts/ABI package to PyPI
publish_python: build_python
	ls -la dist
	twine upload dist/*

download_exe:
	curl -o $(XBRNETWORK) \
		https://download.crossbario.com/xbrnetwork/linux-amd64/xbrnetwork-latest
	chmod +x $(XBRNETWORK)
	$(XBRNETWORK) version

upload_exe:
	aws s3 cp --acl public-read \
		./dist/xbrnetwork \
		s3://download.crossbario.com/xbrnetwork/linux-amd64/${XBRNETWORK_EXE_FILENAME}
	aws s3 cp --acl public-read \
		./dist/xbrnetwork \
		s3://download.crossbario.com/xbrnetwork/linux-amd64/xbrnetwork-latest
	# aws s3api copy-object --acl public-read --copy-source \
	# 	download.crossbario.com/xbrnetwork/linux-amd64/${XBRNETWORK_EXE_FILENAME} \
	# 	--bucket download.crossbario.com \
	# 	--key xbrnetwork/linux-amd64/xbrnetwork-latest
	aws cloudfront create-invalidation \
		--distribution-id E2QIG9LNGCJSP9 --paths "/xbrnetwork/linux-amd64/*"

test_xbr_schema:
	USE_TWISTED=1 trial autobahn.xbr.test.schema
	USE_ASYNCIO=1 pytest autobahn/xbr/test/schema

# WEB3_INFURA_PROJECT_ID must be defined for this
test_infura:
	time -f "%e" python -c "from web3.auto.infura import w3; print(w3.isConnected())"

test_xbr:
	USE_TWISTED=1 trial autobahn.xbr

test_xbr_cli:
	xbrnetwork
	xbrnetwork version
	xbrnetwork get-member
	xbrnetwork get-market --market=1388ddf6-fe36-4201-b1aa-cb7e36b4cfb3
	xbrnetwork get-actor
	xbrnetwork get-actor --market=1388ddf6-fe36-4201-b1aa-cb7e36b4cfb3

test_xbr_web3:
#	pytest -s -v -rfA autobahn/xbr/test/test_xbr_web3.py
	trial autobahn/xbr/test/test_xbr_web3.py

test_xbr_frealm:
#	pytest -s -v -rfA autobahn/xbr/test/test_xbr_frealm.py
	trial autobahn/xbr/test/test_xbr_frealm.py

test_xbr_argon2:
	USE_ASYNCIO=1 trial autobahn.xbr.test.test_xbr_argon2
	USE_TWISTED=1 trial autobahn.xbr.test.test_xbr_argon2

test_xbr_config:
	USE_TWISTED=1 trial autobahn.xbr.test.test_xbr_config

# deprecated with v21.2.1 (ABI files are no longer bundled in this package)
abi_files:
	curl -s https://xbr.network/lib/abi/xbr-protocol-latest.zip -o /tmp/xbr-protocol-latest.zip
	unzip -t /tmp/xbr-protocol-latest.zip
	rm -rf ${PWD}/autobahn/xbr/contracts
	unzip /tmp/xbr-protocol-latest.zip -d ${PWD}/autobahn/xbr/contracts

test_mnemonic:
	# python -m pytest -rsx autobahn/xbr/test/test_mnemonic.py
	USE_TWISTED=1 trial autobahn.xbr.test

