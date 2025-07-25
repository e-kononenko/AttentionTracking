# AttentionTracking

Mechanism that understands, what items in `SwiftUI` List are interesting to users, based on their viewing time. 

We find visible cells with `GeometryReader` and custom `PreferenceKey`.

Partially visible items (at minimum 70%) are also considered as visible.

Then we process visible items and understand, how long they were visible. 

If an item was visible longer than minimun viewing time, we add it to the result.

We use `Combine` to collect the results and return them in batches.

The view consumes results as `AsyncSequence` and displays them at the overlay.


![Simulator Screen Recording - iPhone 16 Pro - 2025-07-24 at 19 58 10](https://github.com/user-attachments/assets/2abfab3f-1e56-4699-a480-3962a7ab0d00)
