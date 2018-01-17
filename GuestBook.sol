pragma solidity ^0.4.13; // указываем версию компилятора

// gr.vasilkov@gmail.com
// Данный контракт создавался для демонстрации студентам BSU Blockchain and Smartcontracts Lab,
// контракт содержит преднамеренные недостатки безопасности и его не желательно использовать
// в production среде.

// Описание GuestBook:
// + Администратор может менять название гостевой книги
// + Зарегистрированный пользователь может добавлять любое сообщение
// + Пользователи могут ставить рейтинг за сообщение
// + Администратор может уничтожить контракт
// + Администратор может удалить сообщение
// + Администратор может удалить сообщение
// + Имеется возможность назначить нового администратора контракта
// + Имеется поиск сообщения по его id

contract GuestBook {
  address adminAddress; // адрес администратора
  string guestbookName; // название гостевой книги

  // структура хранимых сообщений
  struct notarizedMessage {
    bytes32 message; // рейтинг сообщения
    int rating; // рейтинг сообщения
    uint timeStamp; // временная метка добавления сообщения в GuestBook
  }
  
  // структура хранимых данных пользователей GuestBook
  struct User {
    string nickname; // имя пользователя
    bytes32 city; // город проживания пользователя
    bytes32 country; // страна проживания пользователя
    bytes32 email; // email пользователя
    bytes32[] myMessages; // список хранимых сообщений пользователя
  }
  
  mapping ( uint => notarizedMessage) notarizedMessages; // позволяет отображать данные сообщения по его тексту
  bytes32[] userMessages; // список всех сообщений пользователей

  mapping ( address => User ) Users;   // позволяет отображать данные пользователя по его адресу
  address[] usersByAddress;  // массив всех зарегистрированных пользователей в GuestBook
 
  uint constant public config_price = 10 finney; // стоимость повышения рейтинга сообщения 
  uint messageId = 0; // идентификатор сообщения

  // события для мониторинга
  event registered(string _nickname, address _addr);

  // это конструктор, он имеет тоже наименование, что и контракт. Он получает вызов однажды при развёртывании контракта
  function GuestBook() {  
    adminAddress = msg.sender;  // устанавливаем администратора, чтобы он мог удалить плохих пользователей, если это необходимо
  }

  modifier onlyAdmin() {
    if (msg.sender != adminAddress) revert(); // если отправитель не является администратором, то вызываем исключение
        _;
  }

  // удаляем существующего пользователя из GuestBook. Только администратор может осуществить данное действие
  function removeUser(address _badUser) onlyAdmin returns (bool success) {
    delete Users[_badUser];
    return true;
  }

  // удаляем существующее сообщение из GuestBook. Только администратор может осуществить данное действие
  function removeMessage(uint _badIdMessage) onlyAdmin returns (bool success) {
    delete notarizedMessages[_badIdMessage];
    return true;
  }

  // регистрируем нового пользователя
  function registerNewUser(string nickname, bytes32 city, bytes32 email, bytes32 country) returns (bool success) {
    address thisNewAddress = msg.sender;
    // необходима проверка существующих вводных данных от внешнего пользователя. Например был ли никнейм null или существовал ли пользователь с таким псевдонимом
    if(bytes(Users[msg.sender].nickname).length != 0) revert(); // проверяем наличия существования пользователя
    if(bytes(nickname).length == 0) revert(); // проверяем наличие указанного nickname пользователя для регистрации
    
    Users[thisNewAddress].nickname = nickname;
    Users[thisNewAddress].city = city;
    Users[thisNewAddress].email = email;
    Users[thisNewAddress].country = country;
    usersByAddress.push(thisNewAddress);  // добавляем в список нового пользователя
    
    registered(nickname, thisNewAddress); // обращаемся к событию
    return true;
  }

  // метод позволяющий добавить пользователю новое сообщение.
  function addMessageFromUser(bytes32 _userMessage) returns (bool success) 
  {
    address thisNewAddress = msg.sender;
    if(bytes(Users[thisNewAddress].nickname).length == 0) revert();// убеждаемся что пользователь зарегистрирован в GuestBook
    if(_userMessage.length == 0) revert(); // проверяем наличие сообщения

    messageId++; // увеличиваем на один идентификатор сообщения
    
    // проверяем наличие существующего сообщения в списке всех сообщений
    // Вопрос: почему очень нежелательно использовать следующий цикл? К чему это может привести?
    bool message_found = false;
    for(uint i = 0; i < userMessages.length; i++) 
    {
        if(userMessages[i] == _userMessage) {
            message_found = true; // найдено хоть одно точно такое же сообщение
            break;
        }
    }
    if (message_found == false) userMessages.push(_userMessage); // добавляем в общий список сообщение пользователя

    notarizedMessages[messageId].rating = 0;
    notarizedMessages[messageId].message = _userMessage;
    notarizedMessages[messageId].timeStamp = block.timestamp; // устанавливаем метку времени создания сообщения
    Users[thisNewAddress].myMessages.push(_userMessage); // добавляем сообщение в список сообщений пользователя
    return true;
  }

  // возвращаем список всех зарегистрированных пользователей
  function getUsers() constant returns (address[]) { 
      return usersByAddress; 
  }

  // возвращаем данные зарегистрированного пользователя
  function getUser(address userAddress) constant returns  (string, bytes32, bytes32, bytes32, bytes32[]) {
    return (
            Users[userAddress].nickname,
            Users[userAddress].city,
            Users[userAddress].email,
            Users[userAddress].country,
            Users[userAddress].myMessages
    );
  }

  // возвращаем список всех сообщений
  function getAllMessages() constant returns (bytes32[]) { 
      return userMessages; 
  }

  // возвращаем список сообщений пользователя
  function getUserMessages(address userAddress) constant returns (bytes32[]) {
    return Users[userAddress].myMessages; 
  }

  // получаем данные о сообщении отправив его идентификатор
  function getMessage(uint _messageId) constant returns (bytes32, int, uint)
  {
    return (
        notarizedMessages[_messageId].message,
        notarizedMessages[_messageId].rating,
        notarizedMessages[_messageId].timeStamp
    );
  }
  
  // увеличиваем рейтинг сообщения пользователя
  function changeMessageRating(uint _messageId, bytes32 _vector) payable  returns (bool success) {
    if (_vector != "higher" || _vector != "lower") revert(); // если пользователь не указал вектор рейтинга.
    if (notarizedMessages[_messageId].timeStamp == 0) revert(); // если идентификатор сообщения не существует. Способ определения наличия ключа https://goo.gl/uDfYJx
    if (msg.value != config_price) revert(); //если пользователь не отправил необходимую сумму сердств на повышение рейтинга

    if (_vector == "higher") {    
        notarizedMessages[messageId].rating = notarizedMessages[messageId].rating++; // увеличиваем рейтинг сообщения на один
    }

    if (_vector == "lower") {    
        notarizedMessages[messageId].rating = notarizedMessages[messageId].rating--; // уменьшаем рейтинг сообщения на один
    }    
    
    return true;    
  } 

  // меняем администратора GuestBook
  function changeAdmin(address newAdminAddress) onlyAdmin  returns (bool success) {
    if(bytes(Users[newAdminAddress].nickname).length == 0) revert(); // убеждаемся что пользователь зарегистрирован в GuestBook
    adminAddress = newAdminAddress;
    return true;    
  } 
  
  // меняем название гостевой книги
  function changeGuestBookName(string newGuestBookName) onlyAdmin {
    guestbookName = newGuestBookName;
  } 
  
  // уничтожаем контракт
  function killContract() onlyAdmin {
    selfdestruct(adminAddress);
  }  

}