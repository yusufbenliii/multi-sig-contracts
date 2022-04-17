const HDWalletProvider = require("@truffle/hdwallet-provider");
const fs = require("fs");
const mnemonic = fs.readFileSync(".secret").toString().trim();
const api_key = fs.readFileSync(".api_key").toString();

module.exports = {
  plugins: ["truffle-plugin-verify"],
  api_keys: {
    snowtrace: api_key,
  },
  networks: {
    development: {
      host: "127.0.0.1", // Localhost (default: none)
      port: 8545, // Standard BSC port (default: none)
      network_id: "*", // Any network (default: none)
    },
    fuji: {
      provider: () =>
        new HDWalletProvider(
          mnemonic,
          `https://api.avax-test.network/ext/bc/C/rpc`
        ),
      network_id: 43113,
      timeoutBlocks: 200,
      skipDryRun: true,
    },
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    // timeout: 100000
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "^0.8.0", // A version or constraint - Ex. "^0.5.0"
    },
  },
};
