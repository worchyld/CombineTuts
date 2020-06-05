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
    // create notification name
    let notification = Notification.Name("MyNotification")

    // get value in notification publisher
    let _ = NotificationCenter.default.publisher(for: notification,
                                                         object: nil)
    // publisher knows about 2 events:
    // (1) Values - known as elements
    // (2) Completion event
    // Can publish zero or more values

    let center = NotificationCenter.default

    // create observer to listen for notification
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

// Create a publisher using `Just`, which lets you
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
