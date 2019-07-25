pragma solidity ^0.5.0;
    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint   PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;

    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */
    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping (address => uint) buyers;
        bool isOpen;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping (uint => Event) events;

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */
    modifier onlyOwner {
        require(msg.sender == owner, "Function only callable by the contract owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */
    function addEvent (string memory _desc, string memory _url, uint _tickets) public onlyOwner returns (uint eventID) {
        Event memory newEvent;
        
        newEvent.description = _desc;
        newEvent.website = _url;
        newEvent.totalTickets = _tickets;
        newEvent.isOpen = true;

        eventID = idGenerator;
        events[eventID] = newEvent;  // add the event to storage
        idGenerator += 1;

        emit LogEventAdded(_desc, _url, _tickets, eventID);
        return eventID;
    }
    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. tickets available
            4. sales
            5. isOpen
    */
    function readEvent(uint _id) 
        public 
        view 
        returns (string memory desc, string memory url, uint ticketsAvailable, uint sales, bool isOpen)  
    {
        Event storage eventInstance = events[_id];

        desc = eventInstance.description;
        url = eventInstance.website;
        ticketsAvailable = eventInstance.totalTickets;
        sales = eventInstance.sales;
        isOpen = eventInstance.isOpen;

        return (desc, url, ticketsAvailable, sales, isOpen);
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */
    function buyTickets(uint _id, uint _ticketsToBuy) public payable {
        address payable purchaser = msg.sender;
        Event storage eventInstance = events[_id];
        uint costOfTickets = PRICE_TICKET * _ticketsToBuy;

        require(eventInstance.isOpen, 'This event has already closed');
        require(msg.value >= costOfTickets, 'You have sent insufficient funds for these tickets');
        require(eventInstance.totalTickets >= _ticketsToBuy, 'There are not enough tickets left to fulfill this purchase!');

        eventInstance.buyers[purchaser] +=  _ticketsToBuy;
        eventInstance.sales += _ticketsToBuy;
        eventInstance.totalTickets -= _ticketsToBuy;

        uint remainder = msg.value - costOfTickets;
        purchaser.transfer(remainder);
        emit LogBuyTickets(purchaser, _id, _ticketsToBuy);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */
    function getRefund(uint _id) public {
        Event storage eventInstance = events[_id];
        address payable requester = msg.sender;
        uint ticketsToReturn = eventInstance.buyers[requester];

        require(ticketsToReturn != 0, "You do not have any tickets.");

        eventInstance.buyers[requester] = 0;
        eventInstance.totalTickets +=  ticketsToReturn;
        eventInstance.sales -= ticketsToReturn;
        
        uint refund = PRICE_TICKET * ticketsToReturn;
        requester.transfer(refund);
        emit LogGetRefund(requester, _id, ticketsToReturn);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */
    function getBuyerNumberTickets(uint _id) public view returns (uint tickets) {
        Event storage eventInstance = events[_id];

        tickets = eventInstance.buyers[msg.sender];
        return tickets;
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */
     function endSale(uint _id) public onlyOwner {
        Event storage eventInstance = events[_id];
        eventInstance.isOpen = false;
        uint balance = address(this).balance;
        owner.transfer(balance);
        emit LogEndSale(owner, balance, _id);
    }
}
