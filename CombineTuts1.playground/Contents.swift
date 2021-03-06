import Foundation
import Combine

/*
 Combine basics/notes

 Three key moving pieces in Combine are:
    `publishers`, `operators` and `subscriber`

 `Publisher` = Emits values over time to 1 or more
    interested parties (ie: subscribers) and can emit:
    (1) Output value of publisher's generic Output type
    (2) Successful completion
    (3) Completion with error (Failure)

 `Operator` = Methods declared on Publisher protocol that
    return the same or new publisher; you can chain them
    together.

 `Subscriber` = They do something with the emitted output
    or completion event.

    Note: Publishers do not emit anything unless something
    is subscribed to recieve input
 */

var subscriptions = Set<AnyCancellable>()

example(of: "Publisher") {
    // Create notification name
    let notification = Notification.Name("MyNotification")

    // Get value in notification publisher
    let _ = NotificationCenter.default.publisher(for: notification,
                                                         object: nil)
    // Publisher knows about 2 events:
    // (1) Values - known as elements
    // (2) Completion event
    // Can publish zero or more values

    let center = NotificationCenter.default

    // Create observer to listen for notification
    let observer = center.addObserver(forName: notification,
                                      object: nil,
                                      queue: nil) { (notification) in
                                        print ("Notification received")
    }

    center.post(name: notification, object: nil)

    center.removeObserver(observer)
}

example(of: "Subscriber") {
    let myNotification = Notification.Name("MyNotification")
    let publisher = NotificationCenter.default .publisher(for: myNotification, object: nil)
    let center = NotificationCenter.default

    // Subscribe with sink
    // Attaches a subscriber with closure-based behavior.
    // .sink operator will continue to receive as many values
    //    as the publisher emits.
    let subscription = publisher.sink { _ in
        print ("notification recieved from a publisher")
    }

    center.post(name: myNotification, object: nil)

    subscription.cancel()
}

// :Create a publisher using `Just`, which lets you
//    create a publisher from a primative value type
//    create a subscription to the publisher, and print
//        message of recieved event
//  Just - A publisher that emits an output to each subscriber just once,
//    and then finishes.
example(of: "Just") {
    let just = Just("Hello world")
    _ = just.sink(
        receiveCompletion: {
        print ("Recieved completion", $0)
    }, receiveValue: {
        print ("Recieved value", $0)
    })

    _ = just.sink(
      receiveCompletion: {
        print("Received completion (another)", $0)
      },
      receiveValue: {
        print("Received value (another)", $0)
    })
}

// :Subscribe with assign(to: on)
// enables you to assign the received value to a
//    KVO-compliant property of an object.

example(of: "assign(to:on)") {
    class SomeObject {
        var value: String = "" {
            didSet {
                print (value)
            }
        }
    }

    let object = SomeObject()

    // create a publisher from array of strings
    let publisher = ["Hello", "world!"].publisher

    // assign each value recieved to the value property of the object
    _ = publisher.assign(to: \.value, on: object)
}

example(of: "Custom subscriber") {
    // be a publisher of elements
    let publisher = (1...6).publisher
    //let publisher = ["A", "B", "C", "D", "E", "F"].publisher

    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never

        func receive(subscription: Subscription) {
            // set a max of 3 requests
            subscription.request(.max(3))
        }

        func receive(_ input: Int) -> Subscribers.Demand {
            print ("Received value:", input)

            // publisher has finite number of values. demanding 3
            // this won't hit the completion request
            return .none

            // recieve all values
            //return .unlimited
        }

        func receive(completion: Subscribers.Completion<Never>) {
            print ("recieved completion request", completion)
        }
    }

    let subscriber = IntSubscriber()
    publisher.subscribe(subscriber)
}

// :Example of future
/* After delay, 2nd subscrption recieves the same value,
    future does not reexecute its promise */
/*
example(of: "Future") {
    // emit an int & never fail
     func futureIncrement(
        integer: Int,
        afterDelay delay: TimeInterval) -> Future<Int, Never> {
        Future<Int, Never> { promise in
          print("Original") // prints straight away; future executes as soon as created
          DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
            promise(.success(integer + 1))
          }
        }
      }

    // create a future, firing in 3 seconds
        let future = futureIncrement(integer: 1, afterDelay: 3)

        // 2
        future.sink(receiveCompletion: {
            print($0)
        },
        receiveValue: {
            print($0)
        }) .store(in: &subscriptions)

    // 2nd subscription
    future.sink(receiveCompletion: {
        print("Second", $0)

    },
    receiveValue: {
        print("Second", $0)
    })
    .store(in: &subscriptions)
}*/

// :Example of `subject`
/* Subject acts as a go-between non-Combine code to send
    values to Combine subscribers */

example(of: "PassthroughSubject") {
    enum MyError: Error {
        case test
    }

    // Custom subscriber object
    final class StringSubscriber: Subscriber {
        typealias Input = String
        typealias Failure = MyError

        func receive(subscription: Subscription) {
            subscription.request(.max(2)) // set max to 2
        }

        func receive(_ input: String) -> Subscribers.Demand {
            print ("recieved input ", input)
            return input == "World" ? .max(1) : .none
        }

        func receive(completion: Subscribers.Completion<MyError>) {
            print ("recieved completion", completion)
        }
    }

    let subscriber = StringSubscriber()

    // create instance of passthrough
    let subject = PassthroughSubject<String, MyError>()

    // subscribe
    subject.subscribe(subscriber)

    // create another subscription
    let subscription = subject
        .sink(receiveCompletion: { (completion) in
            print ("recieved completion (sink):", completion)
        }) { (value) in
            print ("received value (sink):", value)
    }

    subject.send("hello")
    subject.send("world")

    subscription.cancel()
    subject.send("Still here")


    // demonstrates that once a publisher sends a single completion event,
    //   error or otherwise; completion ends
    subject.send(completion: .failure(MyError.test))
    subject.send(completion: .finished)
    subject.send("How about another one?") // does not fire, completion recieved
}

/* Instead of storing each subscription as a value,
    you can store multiple subscriptions in a collection of
    AnyCancellable. The collection will then automatically
    cancel each subscription added to it when the collection
    is about to be deinitialized. */

example(of: "CurrentValueSubject") {
    // create subscription set
    var subscriptions = Set<AnyCancellable>()

    // this will publish integers and never publish an error,
    // with an initial value of 0.
    let subject = CurrentValueSubject<Int, Never>(0)

    // create a subscription to the subject and print values received from it.
    subject.sink(receiveValue: { print($0) })
        .store(in: &subscriptions) // 4


    subject.send(1)
    subject.send(2)

    print(subject.value)

    subject.value = 3

    print(subject.value)

    // create a subscription and print the received values.
    // also store that subscription in the subscriptions set.
     subject
        .print()
        .sink(receiveValue: {
                print("Second subscription:", $0)
        })
        .store(in: &subscriptions)

    subject.send(completion: .finished)
}

example(of: "Dynamically adjusting demand") {
    final class IntSubscriber: Subscriber {
        typealias Input = Int
        typealias Failure = Never

        func receive(subscription: Subscription) {
            subscription.request(.max(2))
        }

        func receive(_ input: Int) -> Subscribers.Demand {
            print ("recieved input:", input)

            switch input {
            case 1:
                return .max(2)
            case 3:
                return .max(1)
            default:
                return .none
            }
        }

        func receive(completion: Subscribers.Completion<Never>) {
            print ("Recieved completion:", completion)
        }
    }

    let subcriber = IntSubscriber()

    let subject = PassthroughSubject<Int, Never>()

    subject.subscribe(subcriber)

    subject.send(1)
    subject.send(2)
    subject.send(3)
    subject.send(4)
    subject.send(5)
    subject.send(6)
}

// :TypeErasure
// let subscribers subscribe to receive events from a
//  publisher without being able to access additional
//  details about that publisher

/*
  Type erasure allows you to hide details about the
    publisher that you may not want to expose to subscribers */

example(of: "typeerasure") {
    let subject = PassthroughSubject<Int, Never>()
    let publisher = subject.eraseToAnyPublisher()

    // conforms to anypublisher
    publisher
        .sink(receiveValue: { print ($0) })
        .store(in: &subscriptions)

    subject.send(0)

    // AnyPublisher does not have a send(_:) operator,
    //  so new values cannot be added to
}
