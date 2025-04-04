PGDMP  *    +                }           hotels    17.4    17.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    16495    hotels    DATABASE     �   CREATE DATABASE hotels WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE hotels;
                     postgres    false                        2615    16885    Hotel    SCHEMA        CREATE SCHEMA "Hotel";
    DROP SCHEMA "Hotel";
                     pg_database_owner    false            �           0    0    SCHEMA "Hotel"    COMMENT     7   COMMENT ON SCHEMA "Hotel" IS 'standard public schema';
                        pg_database_owner    false    5            �            1255    16886    check_booking_overlap()    FUNCTION     Q  CREATE FUNCTION "Hotel".check_booking_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM "Hotel"."Booking" b
        JOIN "Hotel"."Book_Room" br ON b.booking_ref = br.booking_ref
        WHERE br.address = NEW.address
          AND br.city = NEW.city
          AND br.room_number = NEW.room_number
          AND daterange(b.start_date, b.end_date, '[]') 
              && daterange(
                  (SELECT start_date FROM "Hotel"."Booking" WHERE booking_ref = NEW.booking_ref),
                  (SELECT end_date FROM "Hotel"."Booking" WHERE booking_ref = NEW.booking_ref),
                  '[]'
              )
    ) THEN
        RAISE EXCEPTION 'Double booking detected for room % at % in %!', 
            NEW.room_number, NEW.address, NEW.city;
    END IF;
    RETURN NEW;
END;
$$;
 /   DROP FUNCTION "Hotel".check_booking_overlap();
       Hotel               postgres    false    5            �            1255    16887    check_booking_room_limit()    FUNCTION     6  CREATE FUNCTION "Hotel".check_booking_room_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) FROM "Hotel"."Book_Room" WHERE booking_ref = NEW.booking_ref) >= 10 THEN
        RAISE EXCEPTION 'A booking cannot contain more than 10 rooms.';
    END IF;
    RETURN NEW;
END;
$$;
 2   DROP FUNCTION "Hotel".check_booking_room_limit();
       Hotel               postgres    false    5            �            1255    16888    check_renting_overlap()    FUNCTION     Q  CREATE FUNCTION "Hotel".check_renting_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM "Hotel"."Renting" b
        JOIN "Hotel"."Rent_Room" br ON b.renting_ref = br.renting_ref
        WHERE br.address = NEW.address
          AND br.city = NEW.city
          AND br.room_number = NEW.room_number
          AND daterange(b.start_date, b.end_date, '[]') 
              && daterange(
                  (SELECT start_date FROM "Hotel"."Renting" WHERE renting_ref = NEW.renting_ref),
                  (SELECT end_date FROM "Hotel"."Renting" WHERE renting_ref = NEW.renting_ref),
                  '[]'
              )
    ) THEN
        RAISE EXCEPTION 'Double booking detected for room % at % in %!', 
            NEW.room_number, NEW.address, NEW.city;
    END IF;
    RETURN NEW;
END;
$$;
 /   DROP FUNCTION "Hotel".check_renting_overlap();
       Hotel               postgres    false    5            �            1255    16889    check_renting_room_limit()    FUNCTION     6  CREATE FUNCTION "Hotel".check_renting_room_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) FROM "Hotel"."Rent_Room" WHERE renting_ref = NEW.renting_ref) >= 10 THEN
        RAISE EXCEPTION 'A booking cannot contain more than 10 rooms.';
    END IF;
    RETURN NEW;
END;
$$;
 2   DROP FUNCTION "Hotel".check_renting_room_limit();
       Hotel               postgres    false    5            �            1255    16890    get_available_rooms(date, date)    FUNCTION     �  CREATE FUNCTION "Hotel".get_available_rooms(check_start_date date, check_end_date date) RETURNS TABLE(city character varying, available_rooms_count integer, start_date date, end_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.city,
        COUNT(r.room_number)::INTEGER AS available_rooms_count,
        check_start_date AS start_date,
        check_end_date AS end_date
    FROM 
        "Hotel"."Room" r
    WHERE 
        NOT EXISTS (
            SELECT 1 FROM "Hotel"."Book_Room" br
            JOIN "Hotel"."Booking" b ON br.booking_ref = b.booking_ref
            WHERE br.address = r.address 
              AND br.city = r.city
              AND br.room_number = r.room_number
              AND (b.start_date, b.end_date) OVERLAPS (check_start_date, check_end_date)
        )
        AND NOT EXISTS (
            SELECT 1 FROM "Hotel"."Rent_Room" rr
            JOIN "Hotel"."Renting" rt ON rr.renting_ref = rt.renting_ref
            WHERE rr.address = r.address 
              AND rr.city = r.city
              AND rr.room_number = r.room_number
              AND (rt.start_date, rt.end_date) OVERLAPS (check_start_date, check_end_date)
        )
    GROUP BY 
        r.city;
END;
$$;
 W   DROP FUNCTION "Hotel".get_available_rooms(check_start_date date, check_end_date date);
       Hotel               postgres    false    5            �            1255    16891 :   get_available_rooms_by_date(date, date, character varying)    FUNCTION       CREATE FUNCTION "Hotel".get_available_rooms_by_date(check_start_date date, check_end_date date, p_city character varying DEFAULT NULL::character varying) RETURNS TABLE(city character varying, address character varying, room_number integer, start_date date, end_date date)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.city,
        r.address,
        r.room_number,
		check_start_date AS start_date,
        check_end_date AS end_date
    FROM 
        "Hotel"."Room" r
    WHERE 
        (p_city IS NULL OR r.city = p_city)
        AND NOT EXISTS (
            SELECT 1 FROM "Hotel"."Book_Room" br
            JOIN "Hotel"."Booking" b ON br.booking_ref = b.booking_ref
            WHERE br.address = r.address 
              AND br.city = r.city
              AND br.room_number = r.room_number
              AND (b.start_date, b.end_date) OVERLAPS (check_start_date, check_end_date)
        )
        AND NOT EXISTS (
            SELECT 1 FROM "Hotel"."Rent_Room" rr
            JOIN "Hotel"."Renting" rt ON rr.renting_ref = rt.renting_ref
            WHERE rr.address = r.address 
              AND rr.city = r.city
              AND rr.room_number = r.room_number
              AND (rt.start_date, rt.end_date) OVERLAPS (check_start_date, check_end_date)
        );
END;
$$;
 y   DROP FUNCTION "Hotel".get_available_rooms_by_date(check_start_date date, check_end_date date, p_city character varying);
       Hotel               postgres    false    5            �            1255    16892 C   get_available_rooms_by_date(date, date, character varying, integer)    FUNCTION     #  CREATE FUNCTION "Hotel".get_available_rooms_by_date(check_start_date date, check_end_date date, p_city character varying DEFAULT NULL::character varying, p_min_capacity integer DEFAULT NULL::integer) RETURNS TABLE(city character varying, address character varying, room_number integer, capacity integer, amenities character varying[], price real, mountain_view boolean, sea_view boolean, extendable boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        r.city,
        r.address,
        r.room_number,
        r.capacity,
        ARRAY(
            SELECT amenity::VARCHAR  -- Explicitly cast to VARCHAR
            FROM "Hotel"."Room_Amenities" ra 
            WHERE ra.address = r.address 
              AND ra.city = r.city 
              AND ra.room_number = r.room_number
        ) AS amenities,
        r.price,
        r.mountain_view,
        r.sea_view,
        r.extendable
    FROM 
        "Hotel"."Room" r
    WHERE 
        (p_city IS NULL OR r.city = p_city)
        AND (p_min_capacity IS NULL OR r.capacity >= p_min_capacity)
        AND NOT EXISTS (
            SELECT 1 FROM "Hotel"."Book_Room" br
            JOIN "Hotel"."Booking" b ON br.booking_ref = b.booking_ref
            WHERE br.address = r.address 
              AND br.city = r.city
              AND br.room_number = r.room_number
              AND (b.start_date, b.end_date) OVERLAPS (check_start_date, check_end_date)
        )
        AND NOT EXISTS (
            SELECT 1 FROM "Hotel"."Rent_Room" rr
            JOIN "Hotel"."Renting" rt ON rr.renting_ref = rt.renting_ref
            WHERE rr.address = r.address 
              AND rr.city = r.city
              AND rr.room_number = r.room_number
              AND (rt.start_date, rt.end_date) OVERLAPS (check_start_date, check_end_date)
        );
END;
$$;
 �   DROP FUNCTION "Hotel".get_available_rooms_by_date(check_start_date date, check_end_date date, p_city character varying, p_min_capacity integer);
       Hotel               postgres    false    5            �            1255    16893    update_number_of_hotels()    FUNCTION     �  CREATE FUNCTION "Hotel".update_number_of_hotels() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- If a hotel is added, increase the count
    IF TG_OP = 'INSERT' THEN
        UPDATE "Hotel"."Chain"
        SET number_of_hotels = (
            SELECT COUNT(*) FROM "Hotel"."Hotel" 
            WHERE "Hotel"."Hotel".name = NEW.name
        )
        WHERE "Hotel"."Chain".name = NEW.name;

    -- If a hotel is deleted, decrease the count
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE "Hotel"."Chain"
        SET number_of_hotels = (
            SELECT COUNT(*) FROM "Hotel"."Hotel" 
            WHERE "Hotel"."Hotel".name = OLD.name
        )
        WHERE "Hotel"."Chain".name = OLD.name;

    -- If a hotel's chain changes, update the count for both old and new chains
    ELSIF TG_OP = 'UPDATE' AND OLD.name IS DISTINCT FROM NEW.name THEN
        -- Decrease count for the old chain
        UPDATE "Hotel"."Chain"
        SET number_of_hotels = (
            SELECT COUNT(*) FROM "Hotel"."Hotel" 
            WHERE "Hotel"."Hotel".name = OLD.name
        )
        WHERE "Hotel"."Chain".name = OLD.name;

        -- Increase count for the new chain
        UPDATE "Hotel"."Chain"
        SET number_of_hotels = (
            SELECT COUNT(*) FROM "Hotel"."Hotel" 
            WHERE "Hotel"."Hotel".name = NEW.name
        )
        WHERE "Hotel"."Chain".name = NEW.name;
    END IF;

    RETURN NULL; -- No modification to the triggering row itself
END;
$$;
 1   DROP FUNCTION "Hotel".update_number_of_hotels();
       Hotel               postgres    false    5                        1255    16894    update_number_of_rooms()    FUNCTION     �  CREATE FUNCTION "Hotel".update_number_of_rooms() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- If a room is added, update the count for the specific hotel
    IF TG_OP = 'INSERT' THEN
        UPDATE "Hotel"."Hotel"
        SET number_rooms = (
            SELECT COUNT(*) 
            FROM "Hotel"."Room" 
            WHERE "Hotel"."Room".address = NEW.address 
              AND "Hotel"."Room".city = NEW.city
        )
        WHERE "Hotel"."Hotel".address = NEW.address 
          AND "Hotel"."Hotel".city = NEW.city;

    -- If a room is deleted, update the count for the specific hotel
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE "Hotel"."Hotel"
        SET number_rooms = (
            SELECT COUNT(*) 
            FROM "Hotel"."Room" 
            WHERE "Hotel"."Room".address = OLD.address 
              AND "Hotel"."Room".city = OLD.city
        )
        WHERE "Hotel"."Hotel".address = OLD.address 
          AND "Hotel"."Hotel".city = OLD.city;
    END IF;

    RETURN NULL;
END;
$$;
 0   DROP FUNCTION "Hotel".update_number_of_rooms();
       Hotel               postgres    false    5            �            1255    16895    update_renting_total_price()    FUNCTION     S  CREATE FUNCTION "Hotel".update_renting_total_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Hotel"."Renting"
    SET total_price = (
        SELECT SUM(r.price * (b.end_date - b.start_date)) 
        FROM "Hotel"."Rent_Room" br
        JOIN "Hotel"."Room" r ON br.room_number = r.room_number 
                   AND br.address = r.address 
                   AND br.city = r.city
        JOIN "Hotel"."Renting" b ON br.renting_ref = b.renting_ref  
        WHERE br.renting_ref = NEW.renting_ref
    )
    WHERE renting_ref = NEW.renting_ref;

    RETURN NEW;
END;
$$;
 4   DROP FUNCTION "Hotel".update_renting_total_price();
       Hotel               postgres    false    5            �            1255    16896    update_total_price()    FUNCTION     K  CREATE FUNCTION "Hotel".update_total_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Hotel"."Booking"
    SET total_price = (
        SELECT SUM(r.price * (b.end_date - b.start_date)) 
        FROM "Hotel"."Book_Room" br
        JOIN "Hotel"."Room" r ON br.room_number = r.room_number 
                   AND br.address = r.address 
                   AND br.city = r.city
        JOIN "Hotel"."Booking" b ON br.booking_ref = b.booking_ref  
        WHERE br.booking_ref = NEW.booking_ref
    )
    WHERE booking_ref = NEW.booking_ref;

    RETURN NEW;
END;
$$;
 ,   DROP FUNCTION "Hotel".update_total_price();
       Hotel               postgres    false    5            �            1259    16897 	   Book_Room    TABLE     �   CREATE TABLE "Hotel"."Book_Room" (
    booking_ref integer NOT NULL,
    room_number integer NOT NULL,
    address character varying NOT NULL,
    city character varying NOT NULL
);
     DROP TABLE "Hotel"."Book_Room";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Book_Room"    ACL     i   GRANT ALL ON TABLE "Hotel"."Book_Room" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Book_Room" TO remote_user;
          Hotel               postgres    false    217            �            1259    16902    Booking    TABLE     �   CREATE TABLE "Hotel"."Booking" (
    booking_ref integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_price real DEFAULT 0 NOT NULL,
    customer_id integer NOT NULL
);
    DROP TABLE "Hotel"."Booking";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Booking"    ACL     e   GRANT ALL ON TABLE "Hotel"."Booking" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Booking" TO remote_user;
          Hotel               postgres    false    218            �            1259    16906    Chain    TABLE     �   CREATE TABLE "Hotel"."Chain" (
    name character varying NOT NULL,
    office_address character varying NOT NULL,
    number_of_hotels integer DEFAULT 0 NOT NULL
);
    DROP TABLE "Hotel"."Chain";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Chain"    ACL     a   GRANT ALL ON TABLE "Hotel"."Chain" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Chain" TO remote_user;
          Hotel               postgres    false    219            �            1259    16912    Chain_Email_Inst    TABLE     w   CREATE TABLE "Hotel"."Chain_Email_Inst" (
    name character varying NOT NULL,
    email character varying NOT NULL
);
 '   DROP TABLE "Hotel"."Chain_Email_Inst";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Chain_Email_Inst"    ACL     w   GRANT ALL ON TABLE "Hotel"."Chain_Email_Inst" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Chain_Email_Inst" TO remote_user;
          Hotel               postgres    false    220            �            1259    16917    Chain_Phone_Inst    TABLE     s   CREATE TABLE "Hotel"."Chain_Phone_Inst" (
    name character varying NOT NULL,
    phone_number bigint NOT NULL
);
 '   DROP TABLE "Hotel"."Chain_Phone_Inst";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Chain_Phone_Inst"    ACL     w   GRANT ALL ON TABLE "Hotel"."Chain_Phone_Inst" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Chain_Phone_Inst" TO remote_user;
          Hotel               postgres    false    221            �            1259    16922    Check_In    TABLE     �   CREATE TABLE "Hotel"."Check_In" (
    renting_ref integer NOT NULL,
    employee_id integer,
    booking_ref integer,
    payment character varying(20)
);
    DROP TABLE "Hotel"."Check_In";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Check_In"    ACL     g   GRANT ALL ON TABLE "Hotel"."Check_In" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Check_In" TO remote_user;
          Hotel               postgres    false    222            �            1259    16925    Customer    TABLE     |  CREATE TABLE "Hotel"."Customer" (
    customer_id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    address character varying NOT NULL,
    id_type character varying NOT NULL,
    id_number integer NOT NULL,
    registration_date date NOT NULL,
    CONSTRAINT id_number CHECK (((id_number >= 0) AND (customer_id >= 0)))
);
    DROP TABLE "Hotel"."Customer";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Customer"    ACL     g   GRANT ALL ON TABLE "Hotel"."Customer" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Customer" TO remote_user;
          Hotel               postgres    false    223            �            1259    16931    Employee    TABLE     �  CREATE TABLE "Hotel"."Employee" (
    employee_id integer NOT NULL,
    first_name character varying NOT NULL,
    last_name character varying NOT NULL,
    address character varying NOT NULL,
    id_type character varying NOT NULL,
    id_number integer NOT NULL,
    hotel_address character varying NOT NULL,
    hotel_city character varying NOT NULL,
    manager_employee_id integer
);
    DROP TABLE "Hotel"."Employee";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Employee"    ACL     g   GRANT ALL ON TABLE "Hotel"."Employee" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Employee" TO remote_user;
          Hotel               postgres    false    224            �            1259    16936    Employee_Role    TABLE     p   CREATE TABLE "Hotel"."Employee_Role" (
    employee_id integer NOT NULL,
    role character varying NOT NULL
);
 $   DROP TABLE "Hotel"."Employee_Role";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Employee_Role"    ACL     q   GRANT ALL ON TABLE "Hotel"."Employee_Role" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Employee_Role" TO remote_user;
          Hotel               postgres    false    225            �            1259    16941    Hotel    TABLE     .  CREATE TABLE "Hotel"."Hotel" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    name character varying NOT NULL,
    rating integer DEFAULT 0 NOT NULL,
    email character varying NOT NULL,
    number_rooms integer DEFAULT 0 NOT NULL,
    manager_id integer NOT NULL
);
    DROP TABLE "Hotel"."Hotel";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Hotel"    ACL     a   GRANT ALL ON TABLE "Hotel"."Hotel" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Hotel" TO remote_user;
          Hotel               postgres    false    226            �            1259    16948    Hotel_Phone_Inst    TABLE     �   CREATE TABLE "Hotel"."Hotel_Phone_Inst" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    phone_number bigint NOT NULL
);
 '   DROP TABLE "Hotel"."Hotel_Phone_Inst";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Hotel_Phone_Inst"    ACL     w   GRANT ALL ON TABLE "Hotel"."Hotel_Phone_Inst" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Hotel_Phone_Inst" TO remote_user;
          Hotel               postgres    false    227            �            1259    16953 	   Rent_Room    TABLE     �   CREATE TABLE "Hotel"."Rent_Room" (
    renting_ref integer NOT NULL,
    room_number integer NOT NULL,
    address character varying NOT NULL,
    city character varying NOT NULL
);
     DROP TABLE "Hotel"."Rent_Room";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Rent_Room"    ACL     i   GRANT ALL ON TABLE "Hotel"."Rent_Room" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Rent_Room" TO remote_user;
          Hotel               postgres    false    228            �            1259    16958    Renting    TABLE     �   CREATE TABLE "Hotel"."Renting" (
    renting_ref integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_price real DEFAULT 0 NOT NULL,
    customer_id integer
);
    DROP TABLE "Hotel"."Renting";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Renting"    ACL     e   GRANT ALL ON TABLE "Hotel"."Renting" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Renting" TO remote_user;
          Hotel               postgres    false    229            �            1259    16962    Room    TABLE     �  CREATE TABLE "Hotel"."Room" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    room_number integer NOT NULL,
    price real NOT NULL,
    capacity integer NOT NULL,
    mountain_view boolean NOT NULL,
    sea_view boolean NOT NULL,
    extendable boolean NOT NULL,
    CONSTRAINT capacity CHECK ((capacity >= 1)),
    CONSTRAINT price CHECK ((price >= (0)::double precision))
);
    DROP TABLE "Hotel"."Room";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Room"    ACL     _   GRANT ALL ON TABLE "Hotel"."Room" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Room" TO remote_user;
          Hotel               postgres    false    230            �            1259    16969    Room_Amenities    TABLE     �   CREATE TABLE "Hotel"."Room_Amenities" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    room_number integer NOT NULL,
    amenity character varying NOT NULL
);
 %   DROP TABLE "Hotel"."Room_Amenities";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Room_Amenities"    ACL     s   GRANT ALL ON TABLE "Hotel"."Room_Amenities" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Room_Amenities" TO remote_user;
          Hotel               postgres    false    231            �            1259    16974    Room_Issues    TABLE     �   CREATE TABLE "Hotel"."Room_Issues" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    room_number integer NOT NULL,
    issue character varying NOT NULL
);
 "   DROP TABLE "Hotel"."Room_Issues";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Room_Issues"    ACL     m   GRANT ALL ON TABLE "Hotel"."Room_Issues" TO PUBLIC;
GRANT ALL ON TABLE "Hotel"."Room_Issues" TO remote_user;
          Hotel               postgres    false    232            �            1259    16979    available_rooms_per_area    VIEW     5  CREATE VIEW "Hotel".available_rooms_per_area AS
 SELECT h.city,
    count(r.room_number) AS available_rooms_count
   FROM ("Hotel"."Room" r
     JOIN "Hotel"."Hotel" h ON ((((r.address)::text = (h.address)::text) AND ((r.city)::text = (h.city)::text))))
  WHERE (NOT (r.room_number IN ( SELECT br.room_number
           FROM ("Hotel"."Book_Room" br
             JOIN "Hotel"."Booking" b ON ((br.booking_ref = b.booking_ref)))
          WHERE ((CURRENT_DATE >= b.start_date) AND (CURRENT_DATE <= b.end_date))
        UNION
         SELECT rr.room_number
           FROM ("Hotel"."Rent_Room" rr
             JOIN "Hotel"."Renting" r_1 ON ((rr.renting_ref = r_1.renting_ref)))
          WHERE ((CURRENT_DATE >= r_1.start_date) AND (CURRENT_DATE <= r_1.end_date)))))
  GROUP BY h.city
  ORDER BY (count(r.room_number)) DESC;
 ,   DROP VIEW "Hotel".available_rooms_per_area;
       Hotel       v       postgres    false    218    218    229    228    226    226    218    217    217    230    230    230    229    229    228    5            �           0    0    TABLE available_rooms_per_area    ACL     �   GRANT ALL ON TABLE "Hotel".available_rooms_per_area TO PUBLIC;
GRANT ALL ON TABLE "Hotel".available_rooms_per_area TO remote_user;
          Hotel               postgres    false    233            �            1259    16984    hotel_total_capacity    VIEW     �  CREATE VIEW "Hotel".hotel_total_capacity AS
 SELECT h.address,
    h.city,
    h.name AS hotel_name,
    sum(r.capacity) AS total_capacity,
    count(r.room_number) AS total_rooms
   FROM ("Hotel"."Room" r
     JOIN "Hotel"."Hotel" h ON ((((r.address)::text = (h.address)::text) AND ((r.city)::text = (h.city)::text))))
  GROUP BY h.address, h.city, h.name
  ORDER BY (sum(r.capacity)) DESC;
 (   DROP VIEW "Hotel".hotel_total_capacity;
       Hotel       v       postgres    false    226    226    230    226    230    230    230    5            �           0    0    TABLE hotel_total_capacity    ACL     {   GRANT ALL ON TABLE "Hotel".hotel_total_capacity TO PUBLIC;
GRANT ALL ON TABLE "Hotel".hotel_total_capacity TO remote_user;
          Hotel               postgres    false    234            �          0    16897 	   Book_Room 
   TABLE DATA           O   COPY "Hotel"."Book_Room" (booking_ref, room_number, address, city) FROM stdin;
    Hotel               postgres    false    217   ��       �          0    16902    Booking 
   TABLE DATA           a   COPY "Hotel"."Booking" (booking_ref, start_date, end_date, total_price, customer_id) FROM stdin;
    Hotel               postgres    false    218   @�       �          0    16906    Chain 
   TABLE DATA           J   COPY "Hotel"."Chain" (name, office_address, number_of_hotels) FROM stdin;
    Hotel               postgres    false    219   ��       �          0    16912    Chain_Email_Inst 
   TABLE DATA           :   COPY "Hotel"."Chain_Email_Inst" (name, email) FROM stdin;
    Hotel               postgres    false    220   L�       �          0    16917    Chain_Phone_Inst 
   TABLE DATA           A   COPY "Hotel"."Chain_Phone_Inst" (name, phone_number) FROM stdin;
    Hotel               postgres    false    221   ��       �          0    16922    Check_In 
   TABLE DATA           U   COPY "Hotel"."Check_In" (renting_ref, employee_id, booking_ref, payment) FROM stdin;
    Hotel               postgres    false    222   M�       �          0    16925    Customer 
   TABLE DATA           y   COPY "Hotel"."Customer" (customer_id, first_name, last_name, address, id_type, id_number, registration_date) FROM stdin;
    Hotel               postgres    false    223   ��       �          0    16931    Employee 
   TABLE DATA           �   COPY "Hotel"."Employee" (employee_id, first_name, last_name, address, id_type, id_number, hotel_address, hotel_city, manager_employee_id) FROM stdin;
    Hotel               postgres    false    224   �       �          0    16936    Employee_Role 
   TABLE DATA           =   COPY "Hotel"."Employee_Role" (employee_id, role) FROM stdin;
    Hotel               postgres    false    225   �       �          0    16941    Hotel 
   TABLE DATA           `   COPY "Hotel"."Hotel" (address, city, name, rating, email, number_rooms, manager_id) FROM stdin;
    Hotel               postgres    false    226   ��       �          0    16948    Hotel_Phone_Inst 
   TABLE DATA           J   COPY "Hotel"."Hotel_Phone_Inst" (address, city, phone_number) FROM stdin;
    Hotel               postgres    false    227   6�       �          0    16953 	   Rent_Room 
   TABLE DATA           O   COPY "Hotel"."Rent_Room" (renting_ref, room_number, address, city) FROM stdin;
    Hotel               postgres    false    228   ��       �          0    16958    Renting 
   TABLE DATA           a   COPY "Hotel"."Renting" (renting_ref, start_date, end_date, total_price, customer_id) FROM stdin;
    Hotel               postgres    false    229   ��       �          0    16962    Room 
   TABLE DATA           s   COPY "Hotel"."Room" (address, city, room_number, price, capacity, mountain_view, sea_view, extendable) FROM stdin;
    Hotel               postgres    false    230   6�       �          0    16969    Room_Amenities 
   TABLE DATA           P   COPY "Hotel"."Room_Amenities" (address, city, room_number, amenity) FROM stdin;
    Hotel               postgres    false    231   G�       �          0    16974    Room_Issues 
   TABLE DATA           K   COPY "Hotel"."Room_Issues" (address, city, room_number, issue) FROM stdin;
    Hotel               postgres    false    232   ��       �           2606    16990    Book_Room Book_Room_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Book_Room"
    ADD CONSTRAINT "Book_Room_pkey" PRIMARY KEY (booking_ref, address, city, room_number);
 G   ALTER TABLE ONLY "Hotel"."Book_Room" DROP CONSTRAINT "Book_Room_pkey";
       Hotel                 postgres    false    217    217    217    217            �           2606    16992    Booking Booking_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY "Hotel"."Booking"
    ADD CONSTRAINT "Booking_pkey" PRIMARY KEY (booking_ref);
 C   ALTER TABLE ONLY "Hotel"."Booking" DROP CONSTRAINT "Booking_pkey";
       Hotel                 postgres    false    218            �           2606    16994 &   Chain_Email_Inst Chain_Email_Inst_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst"
    ADD CONSTRAINT "Chain_Email_Inst_pkey" PRIMARY KEY (name, email);
 U   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst" DROP CONSTRAINT "Chain_Email_Inst_pkey";
       Hotel                 postgres    false    220    220            �           2606    16996 &   Chain_Phone_Inst Chain_Phone_Inst_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst"
    ADD CONSTRAINT "Chain_Phone_Inst_pkey" PRIMARY KEY (name, phone_number);
 U   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst" DROP CONSTRAINT "Chain_Phone_Inst_pkey";
       Hotel                 postgres    false    221    221            �           2606    16998    Chain Chain_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY "Hotel"."Chain"
    ADD CONSTRAINT "Chain_pkey" PRIMARY KEY (name);
 ?   ALTER TABLE ONLY "Hotel"."Chain" DROP CONSTRAINT "Chain_pkey";
       Hotel                 postgres    false    219            �           2606    17000    Check_In Check_In_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT "Check_In_pkey" PRIMARY KEY (renting_ref);
 E   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT "Check_In_pkey";
       Hotel                 postgres    false    222            �           2606    17002    Customer Customer_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY "Hotel"."Customer"
    ADD CONSTRAINT "Customer_pkey" PRIMARY KEY (customer_id);
 E   ALTER TABLE ONLY "Hotel"."Customer" DROP CONSTRAINT "Customer_pkey";
       Hotel                 postgres    false    223            �           2606    17004     Employee_Role Employee_Role_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY "Hotel"."Employee_Role"
    ADD CONSTRAINT "Employee_Role_pkey" PRIMARY KEY (employee_id, role);
 O   ALTER TABLE ONLY "Hotel"."Employee_Role" DROP CONSTRAINT "Employee_Role_pkey";
       Hotel                 postgres    false    225    225            �           2606    17006    Employee Employee_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT "Employee_pkey" PRIMARY KEY (employee_id);
 E   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT "Employee_pkey";
       Hotel                 postgres    false    224            �           2606    17008 &   Hotel_Phone_Inst Hotel_Phone_Inst_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst"
    ADD CONSTRAINT "Hotel_Phone_Inst_pkey" PRIMARY KEY (city, address, phone_number);
 U   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst" DROP CONSTRAINT "Hotel_Phone_Inst_pkey";
       Hotel                 postgres    false    227    227    227            �           2606    17010    Hotel Hotel_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY "Hotel"."Hotel"
    ADD CONSTRAINT "Hotel_pkey" PRIMARY KEY (address, city);
 ?   ALTER TABLE ONLY "Hotel"."Hotel" DROP CONSTRAINT "Hotel_pkey";
       Hotel                 postgres    false    226    226            �           2606    17012    Rent_Room Renting_Room_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Rent_Room"
    ADD CONSTRAINT "Renting_Room_pkey" PRIMARY KEY (room_number, address, city, renting_ref);
 J   ALTER TABLE ONLY "Hotel"."Rent_Room" DROP CONSTRAINT "Renting_Room_pkey";
       Hotel                 postgres    false    228    228    228    228            �           2606    17014    Renting Renting_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY "Hotel"."Renting"
    ADD CONSTRAINT "Renting_pkey" PRIMARY KEY (renting_ref);
 C   ALTER TABLE ONLY "Hotel"."Renting" DROP CONSTRAINT "Renting_pkey";
       Hotel                 postgres    false    229            �           2606    17016 "   Room_Amenities Room_Amenities_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room_Amenities"
    ADD CONSTRAINT "Room_Amenities_pkey" PRIMARY KEY (address, city, room_number, amenity);
 Q   ALTER TABLE ONLY "Hotel"."Room_Amenities" DROP CONSTRAINT "Room_Amenities_pkey";
       Hotel                 postgres    false    231    231    231    231            �           2606    17018    Room_Issues Room_Issues_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY "Hotel"."Room_Issues"
    ADD CONSTRAINT "Room_Issues_pkey" PRIMARY KEY (address, city, room_number, issue);
 K   ALTER TABLE ONLY "Hotel"."Room_Issues" DROP CONSTRAINT "Room_Issues_pkey";
       Hotel                 postgres    false    232    232    232    232            �           2606    17020    Room Room_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY "Hotel"."Room"
    ADD CONSTRAINT "Room_pkey" PRIMARY KEY (address, city, room_number);
 =   ALTER TABLE ONLY "Hotel"."Room" DROP CONSTRAINT "Room_pkey";
       Hotel                 postgres    false    230    230    230            �           2606    17021    Booking booking_length    CHECK CONSTRAINT     s   ALTER TABLE "Hotel"."Booking"
    ADD CONSTRAINT booking_length CHECK (((end_date - start_date) <= 14)) NOT VALID;
 >   ALTER TABLE "Hotel"."Booking" DROP CONSTRAINT booking_length;
       Hotel               postgres    false    218    218    218    218            �           2606    17022    Booking booking_ref    CHECK CONSTRAINT     c   ALTER TABLE "Hotel"."Booking"
    ADD CONSTRAINT booking_ref CHECK ((booking_ref >= 0)) NOT VALID;
 ;   ALTER TABLE "Hotel"."Booking" DROP CONSTRAINT booking_ref;
       Hotel               postgres    false    218    218            �           2606    17023    Employee employee_id    CHECK CONSTRAINT     d   ALTER TABLE "Hotel"."Employee"
    ADD CONSTRAINT employee_id CHECK ((employee_id >= 0)) NOT VALID;
 <   ALTER TABLE "Hotel"."Employee" DROP CONSTRAINT employee_id;
       Hotel               postgres    false    224    224            �           2606    17024    Employee id_number    CHECK CONSTRAINT     `   ALTER TABLE "Hotel"."Employee"
    ADD CONSTRAINT id_number CHECK ((id_number >= 0)) NOT VALID;
 :   ALTER TABLE "Hotel"."Employee" DROP CONSTRAINT id_number;
       Hotel               postgres    false    224    224            �           2606    17026    Customer id_number_unique 
   CONSTRAINT     \   ALTER TABLE ONLY "Hotel"."Customer"
    ADD CONSTRAINT id_number_unique UNIQUE (id_number);
 F   ALTER TABLE ONLY "Hotel"."Customer" DROP CONSTRAINT id_number_unique;
       Hotel                 postgres    false    223            �           2606    17027    Chain number_hotels    CHECK CONSTRAINT     h   ALTER TABLE "Hotel"."Chain"
    ADD CONSTRAINT number_hotels CHECK ((number_of_hotels >= 0)) NOT VALID;
 ;   ALTER TABLE "Hotel"."Chain" DROP CONSTRAINT number_hotels;
       Hotel               postgres    false    219    219            �           2606    17028    Hotel number_rooms    CHECK CONSTRAINT     c   ALTER TABLE "Hotel"."Hotel"
    ADD CONSTRAINT number_rooms CHECK ((number_rooms >= 0)) NOT VALID;
 :   ALTER TABLE "Hotel"."Hotel" DROP CONSTRAINT number_rooms;
       Hotel               postgres    false    226    226            �           2606    17029    Hotel_Phone_Inst phone_number    CHECK CONSTRAINT     �   ALTER TABLE "Hotel"."Hotel_Phone_Inst"
    ADD CONSTRAINT phone_number CHECK (((phone_number >= 1111111111) AND (phone_number <= '9999999999'::bigint))) NOT VALID;
 E   ALTER TABLE "Hotel"."Hotel_Phone_Inst" DROP CONSTRAINT phone_number;
       Hotel               postgres    false    227    227            �           2606    17030 #   Chain_Phone_Inst phone_number_check    CHECK CONSTRAINT     �   ALTER TABLE "Hotel"."Chain_Phone_Inst"
    ADD CONSTRAINT phone_number_check CHECK (((phone_number >= 1111111111) AND (phone_number <= '9999999999'::bigint))) NOT VALID;
 K   ALTER TABLE "Hotel"."Chain_Phone_Inst" DROP CONSTRAINT phone_number_check;
       Hotel               postgres    false    221    221            �           2606    17031    Hotel rating    CHECK CONSTRAINT     k   ALTER TABLE "Hotel"."Hotel"
    ADD CONSTRAINT rating CHECK (((rating >= 1) AND (rating <= 5))) NOT VALID;
 4   ALTER TABLE "Hotel"."Hotel" DROP CONSTRAINT rating;
       Hotel               postgres    false    226    226            �           2606    17032    Renting renting_length    CHECK CONSTRAINT     s   ALTER TABLE "Hotel"."Renting"
    ADD CONSTRAINT renting_length CHECK (((end_date - start_date) <= 14)) NOT VALID;
 >   ALTER TABLE "Hotel"."Renting" DROP CONSTRAINT renting_length;
       Hotel               postgres    false    229    229    229    229            �           2606    17033    Renting renting_ref    CHECK CONSTRAINT     c   ALTER TABLE "Hotel"."Renting"
    ADD CONSTRAINT renting_ref CHECK ((renting_ref >= 0)) NOT VALID;
 ;   ALTER TABLE "Hotel"."Renting" DROP CONSTRAINT renting_ref;
       Hotel               postgres    false    229    229            �           2606    17035    Customer sin_unique 
   CONSTRAINT     V   ALTER TABLE ONLY "Hotel"."Customer"
    ADD CONSTRAINT sin_unique UNIQUE (id_number);
 @   ALTER TABLE ONLY "Hotel"."Customer" DROP CONSTRAINT sin_unique;
       Hotel                 postgres    false    223            �           2606    17037    Employee unique_id 
   CONSTRAINT     W   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT unique_id UNIQUE (employee_id);
 ?   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT unique_id;
       Hotel                 postgres    false    224            �           2606    17039    Employee unique_sin 
   CONSTRAINT     V   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT unique_sin UNIQUE (id_number);
 @   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT unique_sin;
       Hotel                 postgres    false    224            �           1259    17040    Idx_Book_Room_Composite    INDEX     h   CREATE INDEX "Idx_Book_Room_Composite" ON "Hotel"."Book_Room" USING btree (address, city, room_number);
 .   DROP INDEX "Hotel"."Idx_Book_Room_Composite";
       Hotel                 postgres    false    217    217    217            �           1259    17041    Idx_Booking_Dates    INDEX     Z   CREATE INDEX "Idx_Booking_Dates" ON "Hotel"."Booking" USING btree (start_date, end_date);
 (   DROP INDEX "Hotel"."Idx_Booking_Dates";
       Hotel                 postgres    false    218    218            �           1259    17042    Idx_Rent_Room_Composite    INDEX     h   CREATE INDEX "Idx_Rent_Room_Composite" ON "Hotel"."Rent_Room" USING btree (address, city, room_number);
 .   DROP INDEX "Hotel"."Idx_Rent_Room_Composite";
       Hotel                 postgres    false    228    228    228            �           1259    17043    Idx_Renting_Dates    INDEX     Z   CREATE INDEX "Idx_Renting_Dates" ON "Hotel"."Renting" USING btree (start_date, end_date);
 (   DROP INDEX "Hotel"."Idx_Renting_Dates";
       Hotel                 postgres    false    229    229            �           1259    17044    Idx_Room_Location    INDEX     P   CREATE INDEX "Idx_Room_Location" ON "Hotel"."Room" USING btree (address, city);
 (   DROP INDEX "Hotel"."Idx_Room_Location";
       Hotel                 postgres    false    230    230            �           2620    17045 "   Book_Room book_room_insert_trigger    TRIGGER     �   CREATE TRIGGER book_room_insert_trigger AFTER INSERT OR DELETE ON "Hotel"."Book_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_total_price();
 >   DROP TRIGGER book_room_insert_trigger ON "Hotel"."Book_Room";
       Hotel               postgres    false    217    255            �           2620    17046 $   Book_Room enforce_booking_room_limit    TRIGGER     �   CREATE TRIGGER enforce_booking_room_limit BEFORE INSERT ON "Hotel"."Book_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_booking_room_limit();
 @   DROP TRIGGER enforce_booking_room_limit ON "Hotel"."Book_Room";
       Hotel               postgres    false    217    246            �           2620    17047 #   Book_Room enforce_no_double_booking    TRIGGER     �   CREATE TRIGGER enforce_no_double_booking BEFORE INSERT OR UPDATE ON "Hotel"."Book_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_booking_overlap();
 ?   DROP TRIGGER enforce_no_double_booking ON "Hotel"."Book_Room";
       Hotel               postgres    false    252    217            �           2620    17048 #   Rent_Room enforce_no_double_renting    TRIGGER     �   CREATE TRIGGER enforce_no_double_renting BEFORE INSERT OR UPDATE ON "Hotel"."Rent_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_renting_overlap();
 ?   DROP TRIGGER enforce_no_double_renting ON "Hotel"."Rent_Room";
       Hotel               postgres    false    247    228            �           2620    17049 $   Rent_Room enforce_renting_room_limit    TRIGGER     �   CREATE TRIGGER enforce_renting_room_limit BEFORE INSERT ON "Hotel"."Rent_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_renting_room_limit();
 @   DROP TRIGGER enforce_renting_room_limit ON "Hotel"."Rent_Room";
       Hotel               postgres    false    228    248            �           2620    17050    Hotel hotel_count_update    TRIGGER     �   CREATE TRIGGER hotel_count_update AFTER INSERT OR DELETE OR UPDATE ON "Hotel"."Hotel" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_number_of_hotels();
 4   DROP TRIGGER hotel_count_update ON "Hotel"."Hotel";
       Hotel               postgres    false    253    226                        2620    17051 "   Rent_Room rent_room_insert_trigger    TRIGGER     �   CREATE TRIGGER rent_room_insert_trigger AFTER INSERT OR DELETE ON "Hotel"."Rent_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_renting_total_price();
 >   DROP TRIGGER rent_room_insert_trigger ON "Hotel"."Rent_Room";
       Hotel               postgres    false    254    228                       2620    17052    Room room_delete_trigger    TRIGGER     �   CREATE TRIGGER room_delete_trigger AFTER DELETE ON "Hotel"."Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_number_of_rooms();
 4   DROP TRIGGER room_delete_trigger ON "Hotel"."Room";
       Hotel               postgres    false    256    230                       2620    17053    Room room_insert_trigger    TRIGGER     �   CREATE TRIGGER room_insert_trigger AFTER INSERT ON "Hotel"."Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_number_of_rooms();
 4   DROP TRIGGER room_insert_trigger ON "Hotel"."Room";
       Hotel               postgres    false    256    230            �           2606    17054    Chain_Phone_Inst Name    FK CONSTRAINT     {   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst"
    ADD CONSTRAINT "Name" FOREIGN KEY (name) REFERENCES "Hotel"."Chain"(name);
 D   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst" DROP CONSTRAINT "Name";
       Hotel               postgres    false    4800    221    219            �           2606    17059    Check_In booking    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT booking FOREIGN KEY (booking_ref) REFERENCES "Hotel"."Booking"(booking_ref);
 =   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT booking;
       Hotel               postgres    false    222    4797    218            �           2606    17064    Book_Room booking    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Book_Room"
    ADD CONSTRAINT booking FOREIGN KEY (booking_ref) REFERENCES "Hotel"."Booking"(booking_ref) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 >   ALTER TABLE ONLY "Hotel"."Book_Room" DROP CONSTRAINT booking;
       Hotel               postgres    false    217    218    4797            �           2606    17069    Booking customer    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Booking"
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES "Hotel"."Customer"(customer_id);
 =   ALTER TABLE ONLY "Hotel"."Booking" DROP CONSTRAINT customer;
       Hotel               postgres    false    218    223    4808            �           2606    17074    Renting customer    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Renting"
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES "Hotel"."Customer"(customer_id) NOT VALID;
 =   ALTER TABLE ONLY "Hotel"."Renting" DROP CONSTRAINT customer;
       Hotel               postgres    false    223    4808    229            �           2606    17079    Employee_Role employee    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Employee_Role"
    ADD CONSTRAINT employee FOREIGN KEY (employee_id) REFERENCES "Hotel"."Employee"(employee_id);
 C   ALTER TABLE ONLY "Hotel"."Employee_Role" DROP CONSTRAINT employee;
       Hotel               postgres    false    225    224    4814            �           2606    17084    Check_In employee    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT employee FOREIGN KEY (employee_id) REFERENCES "Hotel"."Employee"(employee_id);
 >   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT employee;
       Hotel               postgres    false    224    4814    222            �           2606    17089    Hotel_Phone_Inst hotel    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst"
    ADD CONSTRAINT hotel FOREIGN KEY (city, address) REFERENCES "Hotel"."Hotel"(city, address);
 C   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst" DROP CONSTRAINT hotel;
       Hotel               postgres    false    227    4822    226    226    227            �           2606    17094 
   Room hotel    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room"
    ADD CONSTRAINT hotel FOREIGN KEY (address, city) REFERENCES "Hotel"."Hotel"(address, city) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 7   ALTER TABLE ONLY "Hotel"."Room" DROP CONSTRAINT hotel;
       Hotel               postgres    false    226    230    230    4822    226            �           2606    17099    Employee hotel    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT hotel FOREIGN KEY (hotel_address, hotel_city) REFERENCES "Hotel"."Hotel"(address, city) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 ;   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT hotel;
       Hotel               postgres    false    4822    224    224    226    226            �           2606    17104    Hotel manager    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel"
    ADD CONSTRAINT manager FOREIGN KEY (manager_id) REFERENCES "Hotel"."Employee"(employee_id) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 :   ALTER TABLE ONLY "Hotel"."Hotel" DROP CONSTRAINT manager;
       Hotel               postgres    false    226    224    4814            �           2606    17109    Employee manager    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT manager FOREIGN KEY (manager_employee_id) REFERENCES "Hotel"."Employee"(employee_id) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 =   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT manager;
       Hotel               postgres    false    224    4814    224            �           2606    17114    Chain_Email_Inst name    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst"
    ADD CONSTRAINT name FOREIGN KEY (name) REFERENCES "Hotel"."Chain"(name) NOT VALID;
 B   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst" DROP CONSTRAINT name;
       Hotel               postgres    false    219    4800    220            �           2606    17119 
   Hotel name    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel"
    ADD CONSTRAINT name FOREIGN KEY (name) REFERENCES "Hotel"."Chain"(name) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 7   ALTER TABLE ONLY "Hotel"."Hotel" DROP CONSTRAINT name;
       Hotel               postgres    false    4800    226    219            �           2606    17124    Rent_Room renting    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Rent_Room"
    ADD CONSTRAINT renting FOREIGN KEY (renting_ref) REFERENCES "Hotel"."Renting"(renting_ref);
 >   ALTER TABLE ONLY "Hotel"."Rent_Room" DROP CONSTRAINT renting;
       Hotel               postgres    false    229    228    4830            �           2606    17129    Check_In renting    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT renting FOREIGN KEY (renting_ref) REFERENCES "Hotel"."Renting"(renting_ref);
 =   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT renting;
       Hotel               postgres    false    222    4830    229            �           2606    17134    Room_Amenities room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room_Amenities"
    ADD CONSTRAINT room FOREIGN KEY (address, city, room_number) REFERENCES "Hotel"."Room"(address, city, room_number);
 @   ALTER TABLE ONLY "Hotel"."Room_Amenities" DROP CONSTRAINT room;
       Hotel               postgres    false    230    231    231    231    4833    230    230            �           2606    17139    Room_Issues room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room_Issues"
    ADD CONSTRAINT room FOREIGN KEY (address, city, room_number) REFERENCES "Hotel"."Room"(address, city, room_number);
 =   ALTER TABLE ONLY "Hotel"."Room_Issues" DROP CONSTRAINT room;
       Hotel               postgres    false    230    4833    230    232    232    232    230            �           2606    17144    Rent_Room room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Rent_Room"
    ADD CONSTRAINT room FOREIGN KEY (room_number, address, city) REFERENCES "Hotel"."Room"(room_number, address, city);
 ;   ALTER TABLE ONLY "Hotel"."Rent_Room" DROP CONSTRAINT room;
       Hotel               postgres    false    228    228    228    4833    230    230    230            �           2606    17149    Book_Room room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Book_Room"
    ADD CONSTRAINT room FOREIGN KEY (room_number, address, city) REFERENCES "Hotel"."Room"(room_number, address, city);
 ;   ALTER TABLE ONLY "Hotel"."Book_Room" DROP CONSTRAINT room;
       Hotel               postgres    false    230    230    4833    217    230    217    217            J           826    16884    DEFAULT PRIVILEGES FOR TABLES    DEFAULT ACL     J   ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO PUBLIC;
                        postgres    false            �   t   x�3�440�443P�HM,*.QO���N�K,I�247161�020�(RpT.)JM-�t,���I�(0746Js��W��SsB�07566%����ҒXEFxYvT.�b���� 0Z8      �   �   x���A� е�ņa�.��程V��'.L&���TԊ��ϨH�8Y�R�=��!*�7f>�Z
�-�"'0@���p��h�������v�Π��jؾ ��y�w�^�3RRGLք +��a�+�|Q�      �   g   x�ȱ
�0@�9�
�@|������%؀��B������=E1�
��f�z%y�圙���$ҿ�Ta�D�Tu�R$�C`���g�͛����zeVy����"��H"a      �   m   x�sJ-.Q�Ey�ť�E%I@~9DL/9?��	YQf^Z>�
�Ģ��������GfNI>��0,���Y\�$W�����LI�T��C��̃(����� �]I.      �   t   x�sJ-.Q�Ey���F�&\N�⦦�0q�Ģ����NKSc33S#�PL�#3�$�����̜+(1%��8j������G~NfJb��gX������+F��� �)      �   )   x�3�4�?.S3sK��������Ғ��؀+F��� w8#      �   n   x�3�JL�H,��tJL��M�L-�45Tp��H�Sp,K���LN�+N�44261�4202�50�5��2�t�O��Mv��K�I�+����p{�q����Z���p��qqq ���      �     x��ZYr�8��N����S����edw9��`� �U7�s���%AR�*�c�f�E3�`./_&��;]*���m�<?p^�Z�v�{��Hg�(NҌy���
^7���O�+�r����g2/��zm�V,��~��sY�Oa�0�Y��������j/�{�	�����5WF.���(w1Ʌ��E�.j}T,͜g���Ѽ�BH�F��$�^�]�O�0<�U�wV��ͳF���.'�����S�D͢ع�u^:�O�:���W���$��;�����,�:/�j`���l5���(z=��l��6��O��Y�9ز>?c�|�E3ܳid��R���f�s�_�h̃f��s�k���a�na�p�� x��g��*�f\�c�=W��K!�v�S��� j�����J"�V�w,I�kM��@>d-6��*kٴ�P��]�r���P�<W<TPa����J���i�G�F8�9~}r6�ڸ�wnFٛ�lc�m�'\�|8�PK�ŕF.b��M^̖M��7^�(�<8i[Nr1�l>Jȯ5nw���4tnx]E�h�ܓ�G�k|Y�bA2��emSڜ���M�q���Ԗ�	��r���g3[���Al�b��V�%���\��qM`s��{Ďb��'��D��s ����%��^Zq()����lY;O�Y�jt(�
m���9a�k}�f����]#���,~�C��]þ�mY��9w�!gq����A���F�(tn����%��1~�6</�5ˢ���!E�>��1$m^I ��R�S�e\	 ���&�z%��*�n���+��J�8j=X6���/{�-��E�Q��6�Ơ���J�쩒����	�M]�S�@xhn�K"�_����dK��X�2w�� 㬕� lqN�#˔B�x5�n|v�J����� @������˜es@������9AȾ˼�5�����z�x�	\ټP��w���J�a	�����q�*�y(�ٺ����hP)$ ��70"7��ME�VZ)T��ܔ�]����Y�b��S��	ٍTh�N,˜��
U4����67gT�����"W=��P��ǎc[���E
X��u�~bi���G���)m���E�����S��NR���ly՜�|�Pa�w賫>+ny�:����iB��7�¡�E��I	�� ����$
!�W���,���=j���2�*�z����G���P�ݰ�U�.5F>2�B�E���cײ�
���o#�eOط��&m�	�Y�~��P.n�a�Yv=)�HV�堤-~H܄�y��?��05��0�E���d.Ҧ ����af�U:rQu�Xހ�� ����>���/�����ʝ��	\eyJ�IC��e�� YD>R�~Ys�p�V(�٨c�~f֌� t��}��F���D�8W�Ȭ!���\�
T�y����t���}��" �RUHՉ�%f����t�J� �������g֌��6��(w|[~ J����	��,.�"�&@�k�"'N{.�Z� ~e�f�h�ثޣ�#��FCE9���K��vFf�u�.{����� D�1��E�C 1z3>3*<�y{Z��mj4/�����#�̲�`�"����8x9Ġ�ڋ�W�/c�,�<���@����;CC�l��ӹ6f��C�W��곺h]������,m`����{���+^cmЈu�"?�?2ˮ!�+����O�p����H��vk�@�>Ee��Z��_��4Q�81�ҙ&��*��� �8o0���BoǊ9�vfWbʵ`���%�ޠ�u��E3���K�P[���y�ku6���BQ�x�x�8x��r�ҁ�'�1 �7��ǣ��;��e��;�����yS�N��9-|�f�p M�����߆�;lŷ���]$!�'Ұ-G��Q:!��:GkF��u����dו���#�M���|wFML��B�^�|״�=T��+�RD\��fY�P�-��@
,�o�XOXc<�Q���;�Ԕ*�#�Ժ�]��fD3�{�V�D�:�����/`k����DP��S��w�+%�{>u��Yvq��8��%��",�h�r?�8f����aw���kH�DN��5�2��E�J�ފ�'΃����G��w�H� �z�%���T���Y3��Y�^!�) %�Cշx���kN[�v�_�h��^�H�AD�H�b=��~�(HЛ�T#v��S2��j�3�f��/3к@���R��W3:0�����"͐�5�h&�d0�&��3�屵~�!�*������=k�گ!4��(Q�+úL�<-_I �2?�<`�qE�������&�:,<�ڕ�Q 0����9�g��Ϝof@�"������{ ��Eӎb>3��ƹ�ZiBrlv��v\)wg�4ăm�
-�8�}9J$�D�S�éqi�e����q�*��+}� �~9��P_[�hFCJ~'�V�J�������j��x44+,P������B+rJ�+��{���^J��JC����a������/z7nt���p���:P�<� �"ԐB	WM?}����&�Z��gNQ�3�[]Q�6 C(� �(c��I���,��A�+ѷd�UWݡ�<礊�9�p���ے� �����$�Ӂ^@l ��dzr�}?Sg���?�:h�|(�~f��:pq/��L �
���a�m֜���uD�W`���k ^�ρSI��3
2��cK\��w��)��o�����q�I�f��N�]��D��PhqBǜ���pEX��y�:�Z��B�,��`A������	��I4��9p�H,�p�j�t�X����A�v��/��A�C����o)g䣩����,���:�)��f�ݴ�oNG<�z`"�9^��MMs�!��˫/�
H�Ĳ�+��$��g���!=�s
R�^/�^iZ�G��W>���s�R�9EB��I7�3���W��7r�k���SU<����1��c�5t��^����-[5F��C�^%y1��on�KQ���AW�R�%5kNC�^䞚z�GX�g�ו<�d?����p��{9ˡ�n�ωG�U�CV4���v��S�D3�1{��h�e�OF�4E�ս�f?�>�谼L��'�T9��'W7z[B"�蜸��t�iH�u-A��y�}xE�!���;s�Y?���tVp�
�Zѫ95T|�cFR-�}�K]�vp��>,�)'}�cN��w��50��e��[ݩ�Ro���^
�i��B)M�J4,��|+G��t̉�Co j���~����}@���Z�[H�윎�Lکg����t�ذF�#B��ފ��G��?�U|�cNM��[�{j���q�������O<:ky��eP������T��4��q1
�'���Q���my/�8+� ���2�):�4d�WՉm��E^BW�{s��G��Q �}��(��a�~*զ3��*�(��ޟ�qH��>h��4F�S���#0V
Hu2�J�h�L*�2��
�������s�X�bV�k      �   �  x�eT[��0�6��	R����R��1���^��fn����/P#ɲ��Z���3���SW�U#����}����.�u��e$��R���V�ѻ,;J7�&��2�3��ӆ╪ݦ��)э(w-��IY���9z[�7�{�{��}a�+8�r�aSw�&Z!	�>�[~��Ũ���ӴNL�'L���hd�6��c�>|_�}�SMΛ�3�ZJE<�x��u)�6XP�U���`r�{�4&���&���uI�;�~���URU7������"�&�Sa�#'��c����zI���^iBMq�z'z��$5(�X~IA�z���\q������; q�I��o�]���O.��[�$������>�0E=���<	�Xk>.2���Y��Xga=�f�Ъf�	9��\�������HFf-,�N..r!k�V!CIUs�uv��F|c����UM[������W�X|'��>�όvyC���Հ{��8�54o>�`><&�3�%���-U���QX5�Ǿ9�ə���?q5���^kf�F^��w��R������L$v��#F^��1��ڏ%�m.FC,-֮��	݌��9��=γǝXpm��0Ì�mIw���07^|�f9N�n`�������使��:[���j�kgҰ�m{Z�{��D({a٫��R|�s�\�.�Q�xI�}���`)VH��??�����Yw      �   9  x����n�0��<��#�֦ߪV+�zً� AK�D�F}�b3�c��D@����!"z�~�CU���_�u�T�1���j�Y���ջ-\����td9[�"�����fl{�U�����~��/�o��S��0��_�s�K�3�����+>\❦�k��3|4�Ե{���Ӳ�,�k�c���Ξq�Sޥʩ�Ӭ������=�#|4�q�9������첄���@o�H�-��\�"�e��_q�#UVE�n�,Բ��C6��R��EGW+�"Ԫ(Y�X@Ej�":Z1�ҹ�ݎ�[�y	e蓽���ɠޔ�ȭ2k ���������i���� A;f���<n�����/�x!�񉌧n"��c��i����Z������5ݡ+�_ͽ[�ZuX�[]u���Z�L�:�X�	Q�3'����R�����P�JA�H�}�W(�*���T�M�)PU��,�U��
&m�b�4�	2Ժ`���9�ꢜ�xTmw�&&Y�0Ri5�h���i�/6��7XrQ$�k���~�O��z5:K�{��]1��Ĝ��� v      �   g   x�uΡ� ���
���mnF�����������O9䍞����Un5�!U�u�Qp�	N�z�%���k�9)f�޾@m���8��р�H���7����x ��8�      �   3   x�3�440�443P�HM,*.QO���N�K,I�253��$B��|� �=c      �   6   x�3�4202�50�5��3�9�������&l�kdgpZ�U��qqq �)�      �     x������0Ek�W��D�r�w�)R�I3�`�"�)��+g��I_�WԎ�����ן����������5^3�a��h���x1�>���0z��<%��v1O���ğ��qx�����s)?���	 vX�`Nb���)�$�z]��	�U���R�:�F8�����EH��L��~�T�eI	���7L��B?Z�36ɞ*���G U:M�`8%����� )���Z�[&ު�J�#��6l��,GĕL�$H5(9�@J`�&jN�wJԠ���a�#k!��鑠aa9p�|�^��{&�+E�R�d'P�t\Ý�:+,�����-���n!0��)�ң�zڦ'"��+vB��Ec|;�|f���>��D�&�EH���:�±o�!`����x�k�:!� ��GH�P[n�Z��E:��	<��Q��F�}����h�mm� ��ӊ�?աp����Y��A���G@vQ�'�y�fy�v=����>����գ�z��a�wSD��H�l�͟��Z�4E�
u�G��{D7X�a�[����(R�K�{=A������OA���9R��MQc3!����Q�W�U)��i!գ��;	�4uJQhOdU�"{Z��QdO���2�	��),��������ɨȞv�B�I{D:�Y)
���v39hOaV�B{2�����9i/q�� YJr�ۓ�(R���Q��rn�$��+#*>Jx{rm���~QS�6��%�]��&�ȳ�VjU�"�Z��О��("����!<�\2�U�LPo�Z*6(�4����E��%�?�ON�=B�o&D���8��M54(�E�v��S��<���E��{�?�A!��-�KE�}=zD��z�shPs&�B�1\i0w����zA��ң�tR��!����K�(
�������sJQhO��oObO�H=:+{BHVtj��=-�G���=!ĕ�W���6oA��n�؞H���Dʞ�s�r�ʨ���R�Ӫ��4����$ODP]��G�=y��O�:��G��>��"$W[⸓8T7.!�J�>�#7?b�~�F�fZ[�"h{�r��j-�RA��yV�����\�#C?��b�K�B�lc[&0c�;C4ƞP⸓\$�a%�%
��/�0NAi�������8�$�����J�n��O-�*�9���K���al���g���8��`�CԌ���s_3b�kF�}ͽ_ɖ�Y>�*T#}/��?���      �   ,   x�343P�HM,*.QO���N�K,I�440��������� ��	�      �   5   x�343P�HM,*.QO���N�K,I�440�t*��N�S(���I-����� 9_1     