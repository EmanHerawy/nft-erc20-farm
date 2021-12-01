// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments, network }) => {
  // let SimpleToken = await ethers.getContractFactory('SimpleToken')
  const { deploy } = deployments

  await deploy('SimpleToken', {
    from: deployer,
    args: [
      name,
      symbol,
     
    ],
    log: true,
  })
}

module.exports.tags = ['SimpleToken']
