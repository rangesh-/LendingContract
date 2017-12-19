pragma solidity ^0.4.4;

contract LendingContract{

   uint256 rateofinterestnumerator = 17 ;
   uint256 rateofinterestdenominator= 2 ;
   uint256 noofinstallments=3;
   address _owner ;    

    struct LoanDetails {
         address loanrequestor;
         uint256 amountrequested;
         uint256 amountrepayed;
         uint256 nextinstallementperiod;  
         uint256 installmentcount;
         uint256 amountpaidperinstallment;       
         bool isdefault;
         bool isAccepted;
         bool isLoanclosed;
         bool isLoanRequested; 
    }  
      
    struct LendedLoanDetails{
        address lenderaddress;
        uint256 amountlended;        
    }
     
    
    mapping(address=>uint256) loangurantee;
    mapping(address=>LendedLoanDetails[]) listofloansbyfunders;
    mapping(address=>LoanDetails) loandetails; 
    LoanDetails[] listofloans;
    address[] loanaddress;
    uint256[] loanamount;

    modifier IsValidLoanRequest(){
      require(loangurantee[msg.sender] == 0 );
      _;
    }
 
     function LendingContract() {
       _owner = msg.sender;
     }

    function RequestLoan(uint256 amount) IsValidLoanRequest() {
      var newloandetails =  LoanDetails({loanrequestor:msg.sender, amountrequested : amount ,amountrepayed:0,nextinstallementperiod:0,installmentcount:0,amountpaidperinstallment: (amount * ((1 ether * rateofinterestnumerator) /rateofinterestdenominator)), isLoanRequested :true,isdefault:false,isAccepted :false,isLoanclosed :false});
      listofloans.push(newloandetails);
      loandetails[msg.sender] = newloandetails;
    }

    function getListofLoan() returns(address[],uint256[]) {
        for (var index = 0; index < listofloans.length; index++) {
            if(listofloans[index].isLoanRequested == true && listofloans[index].isAccepted == false ) {
                loanaddress.push(listofloans[index].loanrequestor);
                loanamount.push(listofloans[index].amountrequested);
            }
        }
        return(loanaddress,loanamount);

    } 

    function AcceptLoan(address fundowner,address fundreceiver,uint256 amount) payable {     

     require(loangurantee[fundreceiver] >= amount/2 );
      var istransfersuccessful = fundreceiver.send(amount * 1 ether);   
      if (istransfersuccessful) {
       addLoanpaymentDetails(fundowner,fundreceiver,amount);
      }
    }

    function addLoanpaymentDetails (address fundowner,address fundreceiver,uint256 amount) {
     var prevloandetailsoffunder = listofloansbyfunders[fundowner];
     var loan =LendedLoanDetails({ lenderaddress : fundreceiver, amountlended : amount});
     prevloandetailsoffunder.push(loan);
     listofloansbyfunders[fundowner] = prevloandetailsoffunder;
     var loandetailsoflenderer = loandetails[fundreceiver];
     loandetailsoflenderer.nextinstallementperiod = now * 30 days ; 
     loandetailsoflenderer.isAccepted = true;
     loandetails[fundreceiver] = loandetailsoflenderer;
    }

    function repayLoan(address lender,address tobepayed,uint256 amount) payable{
    
       var istransfersuccessful = tobepayed.send(amount * 1 ether);   
      if (istransfersuccessful) {
       addLoanRepaymentDetails(lender,amount); 
      }
       
    }

    function addLoanRepaymentDetails(address lender,uint256 amount){
         var loandetailsoflenderer = loandetails[lender];
         loandetailsoflenderer.nextinstallementperiod = now * 30 days ; 
         loandetailsoflenderer.installmentcount += 1;
        loandetailsoflenderer.amountrepayed += amount;
       
    }




}