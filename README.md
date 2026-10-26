# SwiftUI: HandleToolbarButtonOverflow

**Pre**

By default, Toolbar's default button style, Glass, or if you are adding your own GlassProminent, (probably) has fixed size horizontal set to true, even on vertical bars.

https://github.com/user-attachments/assets/41ab1017-f21f-40f7-bcb5-d55cd4662043


**Solution**
1. Get the allowed size of the button
2. Fix the button content to the size

<img width="2417" height="1654" alt="demo" src="https://github.com/user-attachments/assets/d7b72acb-6d68-4d21-94b3-558b16ce475a" />


For more discussions on what will NOT work (such as GeometryReader on the button, the content), 
please refer to my blog: [SwiftUI: Is My Toolbar Button Overflowing?]()
