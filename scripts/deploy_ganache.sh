#!/bin/sh

node_modules/.bin/etherlime compile --runs=200
node_modules/.bin/etherlime deploy --file deployment/1_setup_test_environment.js --network ganache --compile false
node_modules/.bin/etherlime deploy --file deployment/2_deploy_contracts.js --network ganache --compile false
node_modules/.bin/etherlime deploy --file deployment/3_setup_contracts.js --network ganache --compile false
node_modules/.bin/etherlime deploy --file deployment/4_finalise_test_environment.js --network ganache --compile false
node_modules/.bin/etherlime deploy --file deployment/5_deploy_modules.js --network ganache --compile false
node_modules/.bin/etherlime deploy --file deployment/6_register_modules.js --network ganache --compile false
node_modules/.bin/etherlime deploy --file deployment/7_upgrade_ens_wf.js --network ganache --compile false