/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */
import { Signer, utils, Contract, ContractFactory, Overrides } from "ethers";
import type { Provider, TransactionRequest } from "@ethersproject/providers";
import type { PromiseOrValue } from "../../common";
import type { Badges, BadgesInterface } from "../../src/Badges";

const _abi = [
  {
    inputs: [
      {
        internalType: "string",
        name: "name",
        type: "string",
      },
      {
        internalType: "string",
        name: "symbol",
        type: "string",
      },
      {
        internalType: "string",
        name: "version",
        type: "string",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Attest",
    type: "event",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "address",
        name: "to",
        type: "address",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "Revoke",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "owner",
        type: "address",
      },
    ],
    name: "balanceOf",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "burn",
    outputs: [],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "address",
        name: "from",
        type: "address",
      },
      {
        internalType: "string",
        name: "uri",
        type: "string",
      },
      {
        internalType: "bytes",
        name: "signature",
        type: "bytes",
      },
    ],
    name: "mintWithPermission",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
  {
    inputs: [],
    name: "name",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "ownerOf",
    outputs: [
      {
        internalType: "address",
        name: "",
        type: "address",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "symbol",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [
      {
        internalType: "uint256",
        name: "tokenId",
        type: "uint256",
      },
    ],
    name: "tokenURI",
    outputs: [
      {
        internalType: "string",
        name: "",
        type: "string",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x6101406040523480156200001257600080fd5b506040516200148f3803806200148f83398101604081905262000035916200027e565b828282828184848160009080519060200190620000549291906200010b565b5080516200006a9060019060208401906200010b565b5050825160208085019190912083518483012060e08290526101008190524660a0818152604080517f8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f81880181905281830187905260608201869052608082019490945230818401528151808203909301835260c0019052805194019390932091935091906080523060c05261012052506200034b98505050505050505050565b82805462000119906200030f565b90600052602060002090601f0160209004810192826200013d576000855562000188565b82601f106200015857805160ff191683800117855562000188565b8280016001018555821562000188579182015b82811115620001885782518255916020019190600101906200016b565b50620001969291506200019a565b5090565b5b808211156200019657600081556001016200019b565b634e487b7160e01b600052604160045260246000fd5b600082601f830112620001d957600080fd5b81516001600160401b0380821115620001f657620001f6620001b1565b604051601f8301601f19908116603f01168101908282118183101715620002215762000221620001b1565b816040528381526020925086838588010111156200023e57600080fd5b600091505b8382101562000262578582018301518183018401529082019062000243565b83821115620002745760008385830101525b9695505050505050565b6000806000606084860312156200029457600080fd5b83516001600160401b0380821115620002ac57600080fd5b620002ba87838801620001c7565b94506020860151915080821115620002d157600080fd5b620002df87838801620001c7565b93506040860151915080821115620002f657600080fd5b506200030586828701620001c7565b9150509250925092565b600181811c908216806200032457607f821691505b6020821081036200034557634e487b7160e01b600052602260045260246000fd5b50919050565b60805160a05160c05160e05161010051610120516110f46200039b6000396000610b3101526000610b8001526000610b5b01526000610ab401526000610ade01526000610b0801526110f46000f3fe608060405234801561001057600080fd5b50600436106100885760003560e01c806370a082311161005b57806370a082311461010a5780638fac1c1c1461012b57806395d89b411461013e578063c87b56dd1461014657600080fd5b806301ffc9a71461008d57806306fdde03146100b557806342966c68146100ca5780636352211e146100df575b600080fd5b6100a061009b366004610ddd565b610159565b60405190151581526020015b60405180910390f35b6100bd610184565b6040516100ac9190610e56565b6100dd6100d8366004610e69565b610216565b005b6100f26100ed366004610e69565b610290565b6040516001600160a01b0390911681526020016100ac565b61011d610118366004610e9e565b6102f5565b6040519081526020016100ac565b61011d610139366004610efb565b61037e565b6100bd610523565b6100bd610154366004610e69565b610532565b60006001600160e01b031982166323eb070760e21b148061017e575061017e82610637565b92915050565b60606000805461019390610f7c565b80601f01602080910402602001604051908101604052809291908181526020018280546101bf90610f7c565b801561020c5780601f106101e15761010080835404028352916020019161020c565b820191906000526020600020905b8154815290600101906020018083116101ef57829003601f168201915b5050505050905090565b61021f81610290565b6001600160a01b0316336001600160a01b0316146102845760405162461bcd60e51b815260206004820152601a60248201527f6275726e3a2073656e646572206d757374206265206f776e657200000000000060448201526064015b60405180910390fd5b61028d81610687565b50565b6000818152600260205260408120546001600160a01b03168061017e5760405162461bcd60e51b815260206004820152601c60248201527f6f776e65724f663a20746f6b656e20646f65736e277420657869737400000000604482015260640161027b565b60006001600160a01b0382166103625760405162461bcd60e51b815260206004820152602c60248201527f62616c616e63654f663a2061646472657373207a65726f206973206e6f74206160448201526b103b30b634b21037bbb732b960a11b606482015260840161027b565b506001600160a01b031660009081526004602052604090205490565b60008061038d8733888861072e565b905060008160001c90506103d8888387878080601f01602080910402602001604051908101604052809392919081815260200183838082843760009201919091525061079592505050565b6104325760405162461bcd60e51b815260206004820152602560248201527f6d696e74576974685065726d697373696f6e3a20696e76616c6964207369676e604482015264617475726560d81b606482015260840161027b565b600881901c600090815260066020526040902054600160ff83161b161561049b5760405162461bcd60e51b815260206004820181905260248201527f6d696e74576974685065726d697373696f6e3a20616c72656164792075736564604482015260640161027b565b60006104a660055490565b90506104e933828a8a8080601f0160208091040260200160405190810160405280939291908181526020018383808284376000920191909152506108e392505050565b506104f8600580546001019055565b600882901c60009081526006602052604090208054600160ff85161b17905598975050505050505050565b60606001805461019390610f7c565b6000818152600260205260409020546060906001600160a01b03166105995760405162461bcd60e51b815260206004820152601d60248201527f746f6b656e5552493a20746f6b656e20646f65736e2774206578697374000000604482015260640161027b565b600082815260036020526040902080546105b290610f7c565b80601f01602080910402602001604051908101604052809291908181526020018280546105de90610f7c565b801561062b5780601f106106005761010080835404028352916020019161062b565b820191906000526020600020905b81548152906001019060200180831161060e57829003601f168201915b50505050509050919050565b60006001600160e01b03198216635b5e139f60e01b148061066857506001600160e01b03198216635164cf4760e01b145b8061017e57506301ffc9a760e01b6001600160e01b031983161461017e565b600061069282610290565b6001600160a01b038116600090815260046020526040812080549293506001929091906106c0908490610fcc565b9091555050600082815260026020908152604080832080546001600160a01b0319169055600390915281206106f491610cf4565b60405182906001600160a01b038316907fec9ab91322523c899ede7830ec9bfc992b5981cdcc27b91162fb23de5791117b90600090a35050565b6000807fd8eb14f4ea0b23f6cb3c182d47430e98ed3da686abfd02df5efd1e126b7840e68686868660405160200161076a959493929190610fe3565b60405160208183030381529060405280519060200120905061078b816109eb565b9695505050505050565b60008060006107a48585610a39565b909250905060008160048111156107bd576107bd611036565b1480156107db5750856001600160a01b0316826001600160a01b0316145b156107eb576001925050506108dc565b600080876001600160a01b0316631626ba7e60e01b888860405160240161081392919061104c565b60408051601f198184030181529181526020820180516001600160e01b03166001600160e01b0319909416939093179092529051610851919061106d565b600060405180830381855afa9150503d806000811461088c576040519150601f19603f3d011682016040523d82523d6000602084013e610891565b606091505b50915091508180156108a4575080516020145b80156108d557508051630b135d3f60e11b906108c99083016020908101908401611089565b6001600160e01b031916145b9450505050505b9392505050565b6000828152600260205260408120546001600160a01b03161561093f5760405162461bcd60e51b81526020600482015260146024820152736d696e743a20746f6b656e49442065786973747360601b604482015260640161027b565b6001600160a01b03841660009081526004602052604081208054600192906109689084906110a6565b9091555050600083815260026020908152604080832080546001600160a01b0319166001600160a01b0389161790556003825290912083516109ac92850190610d2e565b5060405183906001600160a01b038616907fe9274a84b19e9428826de6bae8c48329354f8f0e73f771b97cae2d9dccd45a2790600090a3509092915050565b600061017e6109f8610aa7565b8360405161190160f01b6020820152602281018390526042810182905260009060620160405160208183030381529060405280519060200120905092915050565b6000808251604103610a6f5760208301516040840151606085015160001a610a6387828585610bce565b94509450505050610aa0565b8251604003610a985760208301516040840151610a8d868383610cbb565b935093505050610aa0565b506000905060025b9250929050565b6000306001600160a01b037f000000000000000000000000000000000000000000000000000000000000000016148015610b0057507f000000000000000000000000000000000000000000000000000000000000000046145b15610b2a57507f000000000000000000000000000000000000000000000000000000000000000090565b50604080517f00000000000000000000000000000000000000000000000000000000000000006020808301919091527f0000000000000000000000000000000000000000000000000000000000000000828401527f000000000000000000000000000000000000000000000000000000000000000060608301524660808301523060a0808401919091528351808403909101815260c0909201909252805191012090565b6000807f7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0831115610c055750600090506003610cb2565b8460ff16601b14158015610c1d57508460ff16601c14155b15610c2e5750600090506004610cb2565b6040805160008082526020820180845289905260ff881692820192909252606081018690526080810185905260019060a0016020604051602081039080840390855afa158015610c82573d6000803e3d6000fd5b5050604051601f1901519150506001600160a01b038116610cab57600060019250925050610cb2565b9150600090505b94509492505050565b6000806001600160ff1b03831681610cd860ff86901c601b6110a6565b9050610ce687828885610bce565b935093505050935093915050565b508054610d0090610f7c565b6000825580601f10610d10575050565b601f01602090049060005260206000209081019061028d9190610db2565b828054610d3a90610f7c565b90600052602060002090601f016020900481019282610d5c5760008555610da2565b82601f10610d7557805160ff1916838001178555610da2565b82800160010185558215610da2579182015b82811115610da2578251825591602001919060010190610d87565b50610dae929150610db2565b5090565b5b80821115610dae5760008155600101610db3565b6001600160e01b03198116811461028d57600080fd5b600060208284031215610def57600080fd5b81356108dc81610dc7565b60005b83811015610e15578181015183820152602001610dfd565b83811115610e24576000848401525b50505050565b60008151808452610e42816020860160208601610dfa565b601f01601f19169290920160200192915050565b6020815260006108dc6020830184610e2a565b600060208284031215610e7b57600080fd5b5035919050565b80356001600160a01b0381168114610e9957600080fd5b919050565b600060208284031215610eb057600080fd5b6108dc82610e82565b60008083601f840112610ecb57600080fd5b50813567ffffffffffffffff811115610ee357600080fd5b602083019150836020828501011115610aa057600080fd5b600080600080600060608688031215610f1357600080fd5b610f1c86610e82565b9450602086013567ffffffffffffffff80821115610f3957600080fd5b610f4589838a01610eb9565b90965094506040880135915080821115610f5e57600080fd5b50610f6b88828901610eb9565b969995985093965092949392505050565b600181811c90821680610f9057607f821691505b602082108103610fb057634e487b7160e01b600052602260045260246000fd5b50919050565b634e487b7160e01b600052601160045260246000fd5b600082821015610fde57610fde610fb6565b500390565b8581526001600160a01b0385811660208301528416604082015260806060820181905281018290526000828460a0840137600060a0848401015260a0601f19601f85011683010190509695505050505050565b634e487b7160e01b600052602160045260246000fd5b8281526040602082015260006110656040830184610e2a565b949350505050565b6000825161107f818460208701610dfa565b9190910192915050565b60006020828403121561109b57600080fd5b81516108dc81610dc7565b600082198211156110b9576110b9610fb6565b50019056fea2646970667358221220b26e0461f4159e7e9ac1a6490c56c0bd7a5f03377ab05c75e03ed6c4ed927e1d64736f6c634300080d0033";

type BadgesConstructorParams =
  | [signer?: Signer]
  | ConstructorParameters<typeof ContractFactory>;

const isSuperArgs = (
  xs: BadgesConstructorParams
): xs is ConstructorParameters<typeof ContractFactory> => xs.length > 1;

export class Badges__factory extends ContractFactory {
  constructor(...args: BadgesConstructorParams) {
    if (isSuperArgs(args)) {
      super(...args);
    } else {
      super(_abi, _bytecode, args[0]);
    }
  }

  override deploy(
    name: PromiseOrValue<string>,
    symbol: PromiseOrValue<string>,
    version: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): Promise<Badges> {
    return super.deploy(
      name,
      symbol,
      version,
      overrides || {}
    ) as Promise<Badges>;
  }
  override getDeployTransaction(
    name: PromiseOrValue<string>,
    symbol: PromiseOrValue<string>,
    version: PromiseOrValue<string>,
    overrides?: Overrides & { from?: PromiseOrValue<string> }
  ): TransactionRequest {
    return super.getDeployTransaction(name, symbol, version, overrides || {});
  }
  override attach(address: string): Badges {
    return super.attach(address) as Badges;
  }
  override connect(signer: Signer): Badges__factory {
    return super.connect(signer) as Badges__factory;
  }

  static readonly bytecode = _bytecode;
  static readonly abi = _abi;
  static createInterface(): BadgesInterface {
    return new utils.Interface(_abi) as BadgesInterface;
  }
  static connect(address: string, signerOrProvider: Signer | Provider): Badges {
    return new Contract(address, _abi, signerOrProvider) as Badges;
  }
}
