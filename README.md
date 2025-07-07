# AttentionTracking

Mechanism that understands, what items in `SwiftUI` List are interesting to users, based on their viewing time. 

We find visible cells with `GeometryReader` and custom `PreferenceKey`.

Partially visible items (at minimum 70%) are also considered as visible.

Then we process visible items and understand, how long they were visible. 

If an item is visible longer than minimun viewing time, we add it to the result.

Results are returned in batches with `Combine`.

The view consumes results as `AsyncSequence` and displays them at the overlay.

https://github.com/user-attachments/assets/0b67d4e5-94ca-4124-b1ce-506e6251a347

