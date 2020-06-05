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
