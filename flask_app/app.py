from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi import Request
from pydantic import BaseModel
from fastapi import HTTPException, Request
from fastapi.responses import JSONResponse
import json
from datetime import datetime, timedelta
import os
from jose import JWTError, jwt
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from passlib.context import CryptContext
import sqlite3
import logging

app = FastAPI()


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


DB_PATH = os.getenv('DB_PATH', 'ramen_kiosk.db')


SECRET_KEY = os.getenv("SECRET_KEY", "Kha18059@")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 30


pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


class UserCreate(BaseModel):
    username: str
    password: str
    is_admin: bool = False

class User(BaseModel):
    user_id: int
    username: str
    is_admin: bool

class Token(BaseModel):
    access_token: str
    token_type: str

class RamenOrder(BaseModel):
    flavor_id: int
    soup_base_id: int
    meat_id: int
    spicy_level_id: int

class InventoryUpdate(BaseModel):
    quantity: int

class CartItem(BaseModel):
    flavor_id: int
    soup_base_id: int
    meat_id: int
    spicy_level_id: int
    quantity: int = 1


def get_db_connection():
    try:
        connection = sqlite3.connect(DB_PATH)
        connection.row_factory = sqlite3.Row  
        return connection
    except sqlite3.Error as e:
        logger.error(f"Error connecting to SQLite Database: {e}")
        raise HTTPException(status_code=500, detail="Database connection error")


def create_access_token(data: dict):
    to_encode = data.copy()
    expire = datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=401,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("SELECT user_id, username, is_admin FROM users WHERE username = ?", (username,))
        user = cursor.fetchone()
        cursor.close()
        connection.close()
        if user is None:
            raise credentials_exception
        return User(**user)
    else:
        raise HTTPException(status_code=500, detail="Database connection error")


@app.post("/token")
async def login(request: Request):
    try:
       
        data = await request.json()
        username = data.get('username')
        password = data.get('password')

        if not username or not password:
            raise HTTPException(status_code=400, detail="Username and password are required")

        connection = get_db_connection()
        if connection:
            cursor = connection.cursor()
            cursor.execute("SELECT user_id, username, hashed_password FROM users WHERE username = ?", (username,))
            user = cursor.fetchone()
            cursor.close()
            connection.close()

            if not user:
                raise HTTPException(status_code=400, detail="Incorrect username or password")


            logger.info(f"Attempting login for user: {username}")
            logger.debug(f"Stored hashed password: {user[2]}")  

            if not pwd_context.verify(password, user[2]):  
                logger.warning(f"Password mismatch for user: {username}")
                raise HTTPException(status_code=400, detail="Incorrect username or password")

            access_token = create_access_token(data={"sub": user[1]}) 

         
            return {
                "message": "Login successfully",
                "access_token": access_token,
                "token_type": "bearer"
            }

    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON format")
    except sqlite3.DatabaseError as e:
        logger.error(f"Database error: {e}")
        raise HTTPException(status_code=500, detail="Database error during login")
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        raise HTTPException(status_code=500, detail="Server error during login")



@app.post("/register")
async def register(user: UserCreate):
    connection = get_db_connection()
    
    if connection:
        try:
            cursor = connection.cursor()

           
            cursor.execute("SELECT * FROM users WHERE username = ?", (user.username,))
            existing_user = cursor.fetchone()

            if existing_user:
                cursor.close()
                connection.close()
                raise HTTPException(status_code=400, detail="Username already registered")

           
            hashed_password = pwd_context.hash(user.password)

            
            cursor.execute("INSERT INTO users (username, hashed_password, is_admin) VALUES (?, ?, ?)",
                           (user.username, hashed_password, user.is_admin))
            connection.commit()
            
            cursor.close()
            connection.close()

            return {"message": "User registered successfully"}
        except sqlite3.IntegrityError as e:
            logger.error(f"IntegrityError: {e}")
            raise HTTPException(status_code=400, detail="Integrity error during user creation")
        
        except sqlite3.Error as e:
            logger.error(f"Database error: {e}")
            raise HTTPException(status_code=500, detail="Database error during registration")
        
        except Exception as e:
            logger.error(f"Unexpected error: {e}")
            raise HTTPException(status_code=500, detail="Unexpected error during registration")

    else:
        logger.error("Database connection error.")
        raise HTTPException(status_code=500, detail="Database connection error")

@app.get("/menu")
async def get_menu():
    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("SELECT category, name, item_id FROM menu_items ORDER BY category, name")
        items = cursor.fetchall()
        cursor.close()
        connection.close()
        menu = {}
        for item in items:
            if item['category'] not in menu:
                menu[item['category']] = []
            menu[item['category']].append({"id": item['item_id'], "name": item['name']})
        return menu
    else:
        raise HTTPException(status_code=500, detail="Database connection error")

@app.get("/sales")
async def get_sales(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not authorized")
    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        cursor.execute("""
        SELECT o.order_id, u.username, f.name as flavor, s.name as soup_base, m.name as meat, sp.name as spicy_level, o.order_date
        FROM orders o
        JOIN users u ON o.user_id = u.user_id
        JOIN menu_items f ON o.flavor_id = f.item_id
        JOIN menu_items s ON o.soup_base_id = s.item_id
        JOIN menu_items m ON o.meat_id = m.item_id
        JOIN menu_items sp ON o.spicy_level_id = sp.item_id
        ORDER BY o.order_date DESC
        """)
        sales = cursor.fetchall()
        cursor.close()
        connection.close()
        return sales
    else:
        raise HTTPException(status_code=500, detail="Database connection error")

@app.get("/inventory")
async def get_inventory(current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not Authorized")

    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        cur.execute("SELECT * FROM inventory")
        inventory_data = cur.fetchall()
        cur.close()
        conn.close()
        return inventory_data
    
    raise HTTPException(status_code=500, detail="Database Connection Error") 

@app.put("/inventory/{item_name}")
async def update_inventory(item_name: str, inventory_update: InventoryUpdate, current_user: User = Depends(get_current_user)):
    if not current_user.is_admin:
        raise HTTPException(status_code=403, detail="Not Authorized")

    conn = get_db_connection()
    if conn:
        cur = conn.cursor()
        query = "INSERT INTO inventory (item_name, quantity) VALUES (?, ?) ON CONFLICT(item_name) DO UPDATE SET quantity=?"
        values = (item_name, inventory_update.quantity, inventory_update.quantity)
        cur.execute(query, values)
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Inventory updated successfully"}
    
    raise HTTPException(status_code=500, detail="Database Connection Error") 

@app.post("/add-to-cart")
async def add_to_cart(item: CartItem, current_user: User = Depends(get_current_user)):
    conn = get_db_connection()
    
    if conn:
        cur = conn.cursor()
        query = """
        INSERT INTO cart (user_id, flavor_id, soup_base_id, meat_id, spicy_level_id, quantity)
        VALUES (?, ?, ?, ?, ?, ?)
        """
        values = (current_user.user_id, item.flavor_id, item.soup_base_id, item.meat_id, item.spicy_level_id, item.quantity)
        cur.execute(query, values)
        conn.commit()
        cur.close()
        conn.close()
        return {"message": "Item added to cart successfully"}
    
    raise HTTPException(status_code=500, detail="Database connection error")

@app.get("/cart")
async def get_cart(current_user: User = Depends(get_current_user)):
    conn = get_db_connection() 
    
    if conn:
        cur = conn.cursor(dictionary=True) 
        cur.execute("""
        SELECT c.cart_item_id, f.name AS flavor, s.name AS soup_base, m.name AS meat,
               sp.name AS spicy_level, c.quantity FROM cart c 
        JOIN menu_items f ON c.flavor_id=f.item_id 
        JOIN menu_items s ON c.soup_base_id=s.item_id 
        JOIN menu_items m ON c.meat_id=m.item_id 
        JOIN menu_items sp ON c.spicy_level_id=sp.item_id 
        WHERE c.user_id=%s""", (current_user.user_id,))
        
        cart_items = cur.fetchall() 
        cur.close() 
        conn.close() 
        return cart_items 
    
    raise HTTPException(status_code=500, detail="Database Connection Error") 

@app.delete("/cart/{cart_item_id}")
async def remove_from_cart(cart_item_id: int, current_user: User = Depends(get_current_user)):
    conn = get_db_connection() 
    
    if conn:
        cur = conn.cursor() 
        cur.execute("DELETE FROM cart WHERE cart_item_id=%s AND user_id=%s", (cart_item_id, current_user.user_id)) 
        conn.commit() 
        cur.close() 
        conn.close() 
        return {"message": "Item removed from cart"} 
    
    raise HTTPException(status_code=500, detail="Database Connection Error") 

@app.put("/cart/{cart_item_id}")
async def update_cart_item_quantity(cart_item_id: int, new_quantity: int, current_user: User = Depends(get_current_user)):
    if new_quantity <= 0:
        raise HTTPException(status_code=400, detail="Quantity must be greater than 0") 
    
    conn = get_db_connection()
    if conn:
        cur = conn.cursor() 
        cur.execute("UPDATE cart SET quantity=%s WHERE cart_item_id=%s AND user_id=%s", (new_quantity, cart_item_id, current_user.user_id)) 
        conn.commit() 
        cur.close() 
        conn.close() 
        return {"message": "Cart item quantity updated"} 
    
    raise HTTPException(status_code=500, detail="Database Connection Error") 

@app.post("/place-order")
async def place_order(current_user: User = Depends(get_current_user)):
    conn = get_db_connection()

    if conn:
        cur = conn.cursor()
        try:
           
            conn.start_transaction()

            
            cur.execute("""
            INSERT INTO orders (user_id, flavor_id, soup_base_id, meat_id, spicy_level_id)
            SELECT user_id, flavor_id, soup_base_id, meat_id, spicy_level_id FROM cart WHERE user_id=%s""",
            (current_user.user_id,))
            
            
            cur.execute("DELETE FROM cart WHERE user_id=%s", (current_user.user_id,))
            
            
            conn.commit()
            cur.close()
            conn.close()
            return {"message": "Order placed successfully"} 
        
        except Error as e:

            conn.rollback()
            logger.error(f"Failed to place order: {str(e)}")
            raise HTTPException(status_code=500, detail=f"Failed to place order: {str(e)}") 
        
    else:
        raise HTTPException(status_code=500, detail="Database Connection Error")


@app.post("/order")
async def create_order(order: RamenOrder, current_user: User = Depends(get_current_user)):
    connection = get_db_connection()
    if connection:
        cursor = connection.cursor()
        query = "INSERT INTO orders (user_id, flavor_id, soup_base_id, meat_id, spicy_level_id) VALUES (?, ?, ?, ?, ?)"
        values = (current_user.user_id, order.flavor_id, order.soup_base_id, order.meat_id, order.spicy_level_id)
        cursor.execute(query, values)
        connection.commit()
        order_id = cursor.lastrowid

    
        cursor.execute("UPDATE inventory SET quantity = quantity - 1 WHERE item_name = 'Noodles'")
        cursor.execute("UPDATE inventory SET quantity = quantity - 1 WHERE item_name = (SELECT name FROM menu_items WHERE item_id = ?)", (order.flavor_id,))
        cursor.execute("UPDATE inventory SET quantity = quantity - 1 WHERE item_name = (SELECT name FROM menu_items WHERE item_id = ?)", (order.meat_id,))
        cursor.execute("UPDATE inventory SET quantity = quantity - 1 WHERE item_name = (SELECT name FROM menu_items WHERE item_id = ?)", (order.spicy_level_id,))
        connection.commit()

        cursor.close()
        connection.close()
        return {"message": "Order placed successfully", "order_id": order_id}
    else:
        raise HTTPException(status_code=500, detail="Database connection error")


@app.on_event("startup")
async def startup():
    connection = get_db_connection()
    cursor = connection.cursor()

   
    cursor.execute(""" 
    CREATE TABLE IF NOT EXISTS categories (
        category_id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT UNIQUE NOT NULL
    );
    """)
    cursor.execute(""" 
    CREATE TABLE IF NOT EXISTS users (
        user_id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        hashed_password TEXT NOT NULL,
        is_admin BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)
    cursor.execute(""" 
    CREATE TABLE IF NOT EXISTS menu_items (
        item_id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        UNIQUE(category, name),
        CHECK (category IN ('flavor', 'soup_base', 'meat', 'spicy_level'))
    );
    """)
    cursor.execute(""" 
    CREATE TABLE IF NOT EXISTS orders (
        order_id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        flavor_id INTEGER,
        soup_base_id INTEGER,
        meat_id INTEGER,
        spicy_level_id INTEGER,
        order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (user_id) REFERENCES users(user_id),
        FOREIGN KEY (flavor_id) REFERENCES menu_items(item_id),
        FOREIGN KEY (soup_base_id) REFERENCES menu_items(item_id),
        FOREIGN KEY (meat_id) REFERENCES menu_items(item_id),
        FOREIGN KEY (spicy_level_id) REFERENCES menu_items(item_id)
    );
    """)
    cursor.execute(""" 
    CREATE TABLE IF NOT EXISTS inventory (
        inventory_id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_name TEXT UNIQUE NOT NULL,
        quantity INTEGER NOT NULL,
        last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    """)


    cursor.execute(""" 
    INSERT OR IGNORE INTO menu_items (category, name) VALUES
    ('flavor', 'Shoyu'), ('flavor', 'Miso'), ('flavor', 'Tonkotsu'), ('flavor','Indomie'),
    ('soup_base', 'Rich'), ('soup_base', 'Light'), ('soup_base', 'Spicy'),
    ('meat', 'Pork'), ('meat', 'Chicken'), ('meat', 'Beef'), ('meat', 'Tofu'),
    ('spicy_level', 'Not Spicy'), ('spicy_level', 'Mild'), ('spicy_level', 'Medium'), ('spicy_level', 'Hot');
    """)

  
    cursor.execute(""" 
    INSERT OR IGNORE INTO inventory (item_name, quantity) VALUES
    ('Noodles', 1000), ('Pork', 500), ('Chicken', 500), ('Beef', 500), ('Tofu', 500),
    ('Eggs', 1000), ('Seaweed', 1000), ('Green Onions', 1000);
    """)

    connection.commit()
    cursor.close()
    connection.close()
    
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
