pragma solidity ^0.4.17;
import "./HealthContract.sol";

library ComLib{
function FeedbackToNum(HealthContract.FeedbackType value) 
        public
        pure 
        returns (uint){
            if(value==HealthContract.FeedbackType.Poor)
                return 1;
            else if(value==HealthContract.FeedbackType.Average)
                return 2;
            else if(value==HealthContract.FeedbackType.Good)
                return 3;
            else if(value==HealthContract.FeedbackType.Best)
                return 4;
            else if(value==HealthContract.FeedbackType.Exceptional)
                return 5;
        }
        
    function NumToFeedback(uint value) 
        public
        pure 
        returns (HealthContract.FeedbackType){
            if(value==1)
                return HealthContract.FeedbackType.Poor;
            else if(value==2)
                return HealthContract.FeedbackType.Average;
            else if(value==3)
                return HealthContract.FeedbackType.Good;
            else if(value==4)
                return HealthContract.FeedbackType.Best;
            else if(value==5)
                return HealthContract.FeedbackType.Exceptional;
        }
}
