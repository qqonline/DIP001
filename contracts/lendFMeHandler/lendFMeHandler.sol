pragma solidity ^0.5.4;

import '../DSLibrary/DSAuth.sol';
import '../DSLibrary/DSMath.sol';
import '../interface/ITargetHandler.sol';
import '../interface/IDispatcher.sol';
import '../interface/IERC20.sol';

interface ILendFMe {
	function supply(address _token, uint _amounts) external returns (uint);
	function withdraw(address _token, uint _amounts) external returns (uint);
	function getSupplyBalance(address _user, address _token) external view returns (uint256);
}

contract lendFMeHandler is ITargetHandler, DSAuth, DSMath {

	address targetAddr;
	address token;
	address dispatcher;	
	uint256 principle;

	constructor (address _targetAddr, address _token) public {
		targetAddr = _targetAddr;
		token = _token;
		IERC20(token).approve(_targetAddr, uint256(-1));
	}


	function setDispatcher(address _dispatcher) public {
		dispatcher = _dispatcher;
	} 

	// trigger token deposit
	function trigger() external returns (bool) {
		uint256 amount = IERC20(token).balanceOf(address(this));
		principle = add(principle, amount);
		ILendFMe(targetAddr).supply(address(token), amount);
		return true;
	}

	function withdraw(uint256 _amounts) external returns (bool){
		require(msg.sender == dispatcher, "sender must be owner");
		// check the fund in the reserve (contract balance) is enough or not
		// if not enough, drain from the defi
		uint256 _tokenBalance = IERC20(token).balanceOf(address(this));
		if (_tokenBalance < _amounts) {
			ILendFMe(targetAddr).withdraw(address(token), sub(_amounts, _tokenBalance));
		}

		principle = sub(principle, _amounts);
		require(IERC20(token).transfer(IDispatcher(dispatcher).getFund(), _amounts));
		return true;
	}

	function withdrawProfit() external returns (bool){
		uint256 _amount = sub(ILendFMe(targetAddr).getSupplyBalance(address(this), address(token)), principle);
		ILendFMe(targetAddr).withdraw(address(token), _amount);
		require(IERC20(token).transfer(IDispatcher(dispatcher).getProfitBeneficiary(), _amount));
		return true;
	}

	function getBalance() external view returns (uint256) {
		return ILendFMe(targetAddr).getSupplyBalance(address(this), address(token));
	}

	function getPrinciple() external view returns (uint256) {
		return principle;
	}

	function getProfit() external view returns (uint256) {
		return sub(ILendFMe(targetAddr).getSupplyBalance(address(this), address(token)), principle);
	}

	function getTargetAddress() public view returns (address) {
		return targetAddr;
	}

	function getToken() view external returns (address) {
		return token;
	}

	function getDispatcher() view public returns (address) {
		return dispatcher;
	}
}