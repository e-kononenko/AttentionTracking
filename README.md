# AttentionTracking

Mechanism that understands, what items in `SwiftUI` List are interesting to users, based on their viewing time. 

We find visible cells with `GeometryReader` and custom `PreferenceKey`.

Then we process visible ids and understand, how long they were visible. 

If they were visible longer than minimun viewing time, we add it to the result.

Results are added to batches with `Combine`.

The view consumes result as `AsyncSequence` and displays it at the overlay.

https://github.com/user-attachments/assets/0b67d4e5-94ca-4124-b1ce-506e6251a347

