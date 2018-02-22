pragma solidity ^0.4.0;
import "./TokenERC20.sol";
import "./ComLib.sol";

contract HealthContract is TokenERC20{
    //possible roles in this contract
    enum PartyType  { Patient, Provider, Payor } 

    //feedback types
    enum FeedbackType { NoN, Poor, Average, Good, Best, Exceptional }
    
    //Entity have address, type and provider entity (hospital or doctor) will have average rating
    struct Entity {
        address addr;
        PartyType partytype; 
        FeedbackType averageRating; //only for provider
    }

    //list of entities already registered
    mapping (address => Entity) public Entities;
    

    struct HealthServiceTransaction {
        //SHA256 hash of health record stored in external Database
        //Merkle tree is used for reducing multiple records ( lab reports, doctor prescription,..etc) to a single hash
        bytes32 healthrecordhash;
        Entity patient;

        //provider can be hospital, clinic, doctor or any party providing health service
        Entity provider; 
        Entity insuranceProvider;

        //this is amount requested from provider (i.e. hospital) after services
        uint256 amountRequested;
        bool paid;

        //each transaction will have actual feedback by patient to provider
        FeedbackType feedback;
    }
    
    uint256 numRecord;
    mapping (uint256 => HealthServiceTransaction) public PatientsRecords;

    //modifier for ensuring only prvider (hospital,doctor,clinic,..etc) access
    modifier onlyByProvider()
    {
        require(Entities[msg.sender].addr != address(0x0));
        require(Entities[msg.sender].partytype == PartyType.Provider);
        _;

    }

    //modifier for ensuring only Insurance agent can access
    modifier onlyByInsuranceAgent()
    {
        require(Entities[msg.sender].addr != address(0x0));
        require(Entities[msg.sender].partytype == PartyType.Payor);
        _;

    }

    //rating event for external parties information
    event Rate(address indexed from, address indexed to, uint256 txId, FeedbackType value);
    
    /*function when a provider (hospital, dorctor, clinic,..etc) provides health service to a patient
    after service provision patient health record is stored in external traditional relational database from frontend web app
    and its hash is stored in blockchain as _healthrecordhash, 
    this function is only called by provider.
    */
    function createHealthRecord(bytes32 _healthrecordhash, address _patient, 
        address _insuranceProvider, uint256 _amountRequested) 
            public 
            onlyByProvider 
            returns (uint256 transactionID)  {
            bool canPay =  _amountRequested <= allowance[_insuranceProvider][_patient] ||
                _amountRequested <= balanceOf[_patient];
            
            require(canPay);
            
            require(Entities[_patient].addr != address(0x0));
            require(Entities[msg.sender].addr != address(0x0));
            require(Entities[_insuranceProvider].addr != address(0x0));
            
            Entity memory _patientObj = Entities[_patient];
            Entity memory _providerObj = Entities[msg.sender];
            Entity memory _insuranceProviderObj = Entities[_insuranceProvider];
            
            transactionID = numRecord++;
            
            PatientsRecords[transactionID]=HealthServiceTransaction(_healthrecordhash,_patientObj,_providerObj,
                                                                        _insuranceProviderObj,_amountRequested,false,FeedbackType.NoN);
      
    }
    
    /*this function is called by patient after health service, the function call is controlled by transaction id
    of previous health service record provided */
    function rateProvider(uint256 txId, FeedbackType rating)
        public {
        require(Entities[msg.sender].addr != address(0x0));
        require(Entities[msg.sender].partytype == PartyType.Patient);
        
        PatientsRecords[txId].feedback = rating;
        PatientsRecords[txId].provider.averageRating = 
            ComLib.NumToFeedback(( ComLib.FeedbackToNum(PatientsRecords[txId].provider.averageRating) + ComLib.FeedbackToNum(rating))/2);
        //raise event and make it public
        Rate(msg.sender,PatientsRecords[txId].provider.addr,txId,rating);
    }

    /*this function is called by patient after healthservice by provider for paying by him self agaist a transaction id
    of previous health services */
    function payToProvider(address _provider,uint256 _txRecord) 
        public{
        require(PatientsRecords[_txRecord].healthrecordhash != bytes32(0x0));
        require(Entities[_provider].addr != address(0x0));
        
        uint256 value = PatientsRecords[_txRecord].amountRequested;
        
        PatientsRecords[_txRecord].paid = 
            transfer(_provider,value);
    }
    
    /*this function is called by patient after healthservice by provider for paying by insurance agaist a transaction id
    of previous health services */
    function payToProviderFromInsurance(address _provider,address _insuranceAgent,uint256 _txRecord) 
        public{
        require(PatientsRecords[_txRecord].healthrecordhash != bytes32(0x0));
        require(Entities[_provider].addr != address(0x0));
        require(Entities[_insuranceAgent].addr != address(0x0));
        
        uint256 _value = PatientsRecords[_txRecord].amountRequested;
        
        PatientsRecords[_txRecord].paid = 
            transferFrom(_insuranceAgent, _provider,  _value);

    }
    
    /*this function is called by insurance agent where he allows patient some amount for health service */
    function transferInsurancePackageAmout(address _patient, uint256 _amount, bytes _extraData)        
        public 
        onlyByInsuranceAgent
        returns (bool success){
            
        return approveAndCall(_patient,_amount,_extraData);
    }

    /*simplely for registration of any party type in smart contract */
    function registerParty(address _party, PartyType _type)
        public{
            Entities[_party] = Entity(_party,_type,FeedbackType.NoN);
        }
}
