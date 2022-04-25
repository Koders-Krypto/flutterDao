import 'dart:convert';
import 'dart:io';
import 'package:dao/walletConnectCred.dart';
import 'package:ethers/ethers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wallet_connect/wallet_connect.dart';
import 'package:walletconnect_dart/walletconnect_dart.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web3dart/crypto.dart';
import 'package:device_apps/device_apps.dart';
import 'package:path/path.dart' show join, dirname;

class Web3Connect {
  Web3Connect(this.context);
  String account = "";
  late WalletConnectEthereumCredentials credentials;
  late WalletConnect connector;
  late WCClient _wcClient;
  late SharedPreferences _prefs;
  WCSessionStore? _sessionStore;
  String rpcUrl = 'https://rpc.ftm.tools/';
  late SessionStatus? session;
  int chainId = 250; //fantom testnet
  String contract = "";
  String balance = "";
  final BuildContext context;
  Web3Client client = Web3Client("", http.Client());
  String FantomBulls = "0xf2b4e66411905d08Cf708526fc76a399cb4Dc7F2";

  late final balanceFunction;
  late final tokenOfOwnerByIndex;
  late final mintNft;
  late final smartContract;

  enterRpcUrl(String rpcUrl) {
    this.rpcUrl = rpcUrl;
  }

  enterChainId(int chainId) {
    this.chainId = chainId;
  }

  connect() async {
    await _walletConnect();
  }

  disconnect() async {
    await connector.killSession();
  }

  transation(Transaction transaction) async {
    try {
      Transaction transaction = Transaction(
        from: EthereumAddress.fromHex(account),
        to: EthereumAddress.fromHex(
            "0xc160Efc3af51ebc6fC4c517cA941a6999Ce0beC0"),
        value: EtherAmount.inWei(BigInt.from(1000000000000000000 * 0.01)),
      );
      EthereumWalletConnectProvider provider =
          EthereumWalletConnectProvider(connector);
      final credentials = WalletConnectEthereumCredentials(provider: provider);
      bool isInstalled = await DeviceApps.isAppInstalled('io.metamask');
      if (isInstalled) {
        DeviceApps.openApp('io.metamask');
        final txBytes = await client.sendTransaction(credentials, transaction);

        return txBytes;
      } else {
        var snackBar = const SnackBar(content: Text('Please install metamask'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (err) {
      var snackBar = SnackBar(content: Text(err.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  getBalance() async {
    var provider = ethers.providers.jsonRpcProvider(url: rpcUrl);
    final balancec = await provider.getBalance(account);
    return double.parse(ethers.utils.formatEther(balancec)).toStringAsFixed(3);
  }

  _walletConnect() async {
    connector = WalletConnect(
      bridge: 'https://bridge.walletconnect.org',
      clientMeta: const PeerMeta(
        name: 'WalletConnect',
        description: 'WalletConnect Developer App',
        url: 'https://walletconnect.org',
        icons: [
          'https://gblobscdn.gitbook.com/spaces%2F-LJJeCjcLrr53DcT1Ml7%2Favatar.png?alt=media'
        ],
      ),
    );
    // Subscribe to events
    connector.on('connect', (session) => print(session));
    connector.on('session_update', (payload) => print(payload));
    connector.on('disconnect', (session) => print(session));
    connector.on('transaction', (payload) => print(payload));
    //Create a new session
    //await launch uri lets you choose which wallet you want to connect to
    if (!connector.connected) {
      session = await connector.createSession(
          chainId: chainId, onDisplayUri: (uri) async => {await launch(uri)});
    }
    account = session!.accounts[0];

    if (account != "") {
      client = Web3Client(rpcUrl, http.Client());
      EthereumWalletConnectProvider provider =
          EthereumWalletConnectProvider(connector);
      credentials = WalletConnectEthereumCredentials(provider: provider);
      // contract = YourContract(address: "contractAddr", client: client);
    }
  }

  loadContract() async {
    try {
      final res = await DefaultAssetBundle.of(context)
          .loadString("assets/FantomBulls.json");
      smartContract = DeployedContract(ContractAbi.fromJson(res, 'FantomBulls'),
          EthereumAddress.fromHex(FantomBulls));

      balanceFunction = smartContract.function('balanceOf');
      tokenOfOwnerByIndex = smartContract.function('tokenOfOwnerByIndex');
      mintNft = smartContract.function('mint');
    } catch (e, trace) {
      var snackBar = SnackBar(content: Text(e.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint("failed to decode\n$e\n$trace");
    }
  }

  balanceOf() async {
    final balance = await client.call(
        contract: smartContract,
        function: balanceFunction,
        params: [EthereumAddress.fromHex(account)]);
    var tokenIds = [];
    int tcount = balance.first.toInt();
    for (var i = 0; i < tcount; i++) {
      final tokenId = await client.call(
          contract: smartContract,
          function: tokenOfOwnerByIndex,
          params: [EthereumAddress.fromHex(account), BigInt.from(i)]);
      tokenIds.add(tokenId.first.toInt());
    }
    return tokenIds.toString();
  }

  mint() async {
    try {
      Transaction transaction = Transaction.callContract(
          from:EthereumAddress.fromHex(account),
          contract: smartContract,
          function: mintNft,
          value: EtherAmount.fromUnitAndValue(EtherUnit.ether, 1),
          parameters: [BigInt.from(1)]);
      EthereumWalletConnectProvider provider =
          EthereumWalletConnectProvider(connector);
      final credentials = WalletConnectEthereumCredentials(provider: provider);
      bool isInstalled = await DeviceApps.isAppInstalled('io.metamask');
      if (isInstalled) {
        DeviceApps.openApp('io.metamask');
        final mint = await client.sendTransaction(credentials, transaction);
        return mint;
      } else {
        var snackBar = const SnackBar(content: Text('Please install metamask'));
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      }
    } catch (e, trace) {
      var snackBar = SnackBar(content: Text(e.toString()));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      debugPrint("failed to decode\n$e\n$trace");
    }
  }
}
