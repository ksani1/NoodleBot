# Ramen Kiosk App

## Team
- **Name(s):** Khalil Muhammad
- **AID(s):** A20526151

## Self-Evaluation Checklist

Tick the boxes (i.e., fill them with 'X's) that apply to your submission:

- [X] The app builds without error
- [X] I tested the app in at least one of the following platforms (check all that apply):
  - [X] iOS simulator / MacOS
  - [X] Android emulator
- [X] There are at least 3 separate screens/pages in the app
- [X] There is at least one stateful widget in the app, backed by a custom model class using a form of state management
- [X] Some user-updateable data is persisted across application launches
- [X] Some application data is accessed from an external source and displayed in the app
- [X] There are at least 5 distinct unit tests, 5 widget tests, and 1 integration test group included in the project


## Questionnaire

### 1. What does your app do?

The **Ramen Kiosk** app is a food ordering application that enables users to browse a ramen menu, manage their shopping cart, and proceed to checkout. Below is a breakdown of its core functionality:

#### Menu Display:
- The app retrieves a menu from a server, categorized by types (e.g., "Spicy," "Vegetarian").
- Each item on the menu includes a name, description, and price.
- Descriptions for menu items are dynamically generated, and prices are randomized (except for spicy items, which have fixed prices).

#### Add to Cart:
- Users can click an "Add to Cart" button beside any item to add it to their shopping cart.
- The app manages the cart and updates it as items are added or removed.

#### Cart Management:
- Users can update the quantity of items in their cart or remove items entirely.
- A detailed summary of the cart is displayed, including price per item, total price, and taxes.

#### Checkout:
- Users can proceed to checkout where they can see a summary of the order, including subtotal, taxes, and the final total.
- Upon confirming the order, a pop-up message appears thanking the user and informing them that the order is being processed.

#### Login:
- The app requires users to log in before accessing the menu. Once logged in, users can browse, add to cart, and check out.
- If the user logs out, they are returned to the login screen.

#### Navigation:
- The app uses a simple navigation flow between screens such as the login screen, menu screen, cart screen, and order summary page.
- After confirming an order, the user is returned to the menu screen.


### 2. What external data source(s) did you use? What form do they take (e.g., RESTful API, cloud-based database, etc.)?

The app uses a **RESTful API** to fetch menu data. The API returns food items in JSON format, which includes various categories (e.g., "Spicy," "Vegetarian"), along with details like name, description, and price. The app makes HTTP requests to this API, and the API requires user authentication via a Bearer token, provided after the user logs in. This ensures that only authenticated users can access the menu data.

The API is hosted on a backend server, likely connected to a cloud-based database such as MySQL or MongoDB. This setup allows for dynamic updates to the menu, as the server can modify the menu data as needed.

### 3. What additional third-party packages or libraries did you use, if any? Why?

- **FastAPI:** To build the backend API, FastAPI was chosen for its high performance and ease of use.
- **Uvicorn:** An ASGI server used to run the FastAPI app, chosen for its lightweight and fast performance.
- **SQLite Connector:** For database interactions with the SQLite database in the backend, providing efficient data management.
- **Flutter:** For building the mobile frontend application, allowing for cross-platform development.
- **Provider:** Used for state management in Flutter, enabling efficient handling of shared state (e.g., cart data, user authentication) across different screens.
- **Dio:** A powerful HTTP client used in Flutter for making API requests, chosen for its flexibility and ease of handling asynchronous operations.

### 4. What form of local data persistence did you use?

The app uses **SharedPreferences** in Flutter to persist essential user data, such as login tokens, and app settings, ensuring that users don't need to log in repeatedly after closing and reopening the app. While the app's cart data and menu are fetched from an external API, **SharedPreferences** ensures that any locally stored user preferences are available across app sessions.

### 5. What workflow is tested by your integration test?

The integration test for this project tests the full user flow from login to order confirmation, which includes the following steps:

1. Logging in with valid credentials.
2. Viewing the menu and adding items to the cart.
3. Viewing the cart and modifying quantities or removing items.
4. Proceeding to checkout, verifying subtotal, taxes, and final total.
5. Confirming the order and ensuring the order completion message is displayed correctly.
6. Navigating back to the menu screen after order confirmation.

## Summary and Reflection

In this project, **FastAPI** was chosen for the backend due to its high performance and its ability to easily integrate with **MySQL**, the database that stores all the application data. On the frontend, **Flutter** was selected because it allows for efficient cross-platform mobile development with a single codebase. **Provider** was used for state management, enabling smooth handling of shared state across different screens.

Throughout the development process, I faced challenges while integrating the backend API with Flutter, especially dealing with asynchronous tasks and managing state correctly. In particular, simulating real API responses and handling edge cases, such as timeouts or incorrect data formats, was tricky. I used mock services during testing to simulate the API's responses.

The integration between **FastAPI** and **Flutter** was smooth, but it required significant trial and error to handle asynchronous data fetching and state management correctly. One key learning from this project was the importance of handling API failures and timeouts gracefully, which is something I initially underestimated.

Overall, the project was rewarding, and it provided valuable insights into how frontend and backend can work together efficiently using modern technologies like **Flutter** and **FastAPI**.