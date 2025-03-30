PGDMP                      }           hotels    17.4    17.2 �    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                           false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                           false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                           false            �           1262    16495    hotels    DATABASE     �   CREATE DATABASE hotels WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'English_United States.1252';
    DROP DATABASE hotels;
                     postgres    false                        2615    2200    Hotel    SCHEMA        CREATE SCHEMA "Hotel";
    DROP SCHEMA "Hotel";
                     pg_database_owner    false            �           0    0    SCHEMA "Hotel"    COMMENT     7   COMMENT ON SCHEMA "Hotel" IS 'standard public schema';
                        pg_database_owner    false    5            �            1255    16777    check_booking_overlap()    FUNCTION     1  CREATE FUNCTION "Hotel".check_booking_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM "Booking" b
        JOIN "Book_Room" br ON b.booking_ref = br.booking_ref
        WHERE br.address = NEW.address
          AND br.city = NEW.city
          AND br.room_number = NEW.room_number
          AND daterange(b.start_date, b.end_date, '[]') 
              && daterange(
                  (SELECT start_date FROM "Booking" WHERE booking_ref = NEW.booking_ref),
                  (SELECT end_date FROM "Booking" WHERE booking_ref = NEW.booking_ref),
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
       Hotel               postgres    false    5            �            1255    16763    check_booking_room_limit()    FUNCTION     .  CREATE FUNCTION "Hotel".check_booking_room_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) FROM "Book_Room" WHERE booking_ref = NEW.booking_ref) >= 10 THEN
        RAISE EXCEPTION 'A booking cannot contain more than 10 rooms.';
    END IF;
    RETURN NEW;
END;
$$;
 2   DROP FUNCTION "Hotel".check_booking_room_limit();
       Hotel               postgres    false    5            �            1255    16781    check_renting_overlap()    FUNCTION     1  CREATE FUNCTION "Hotel".check_renting_overlap() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF EXISTS (
        SELECT 1 
        FROM "Renting" b
        JOIN "Rent_Room" br ON b.renting_ref = br.renting_ref
        WHERE br.address = NEW.address
          AND br.city = NEW.city
          AND br.room_number = NEW.room_number
          AND daterange(b.start_date, b.end_date, '[]') 
              && daterange(
                  (SELECT start_date FROM "Renting" WHERE renting_ref = NEW.renting_ref),
                  (SELECT end_date FROM "Renting" WHERE renting_ref = NEW.renting_ref),
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
       Hotel               postgres    false    5            �            1255    16768    check_renting_room_limit()    FUNCTION     .  CREATE FUNCTION "Hotel".check_renting_room_limit() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    IF (SELECT COUNT(*) FROM "Rent_Room" WHERE renting_ref = NEW.renting_ref) >= 10 THEN
        RAISE EXCEPTION 'A booking cannot contain more than 10 rooms.';
    END IF;
    RETURN NEW;
END;
$$;
 2   DROP FUNCTION "Hotel".check_renting_room_limit();
       Hotel               postgres    false    5            �            1255    16875    get_available_rooms(date, date)    FUNCTION     �  CREATE FUNCTION "Hotel".get_available_rooms(check_start_date date, check_end_date date) RETURNS TABLE(city character varying, available_rooms_count integer, start_date date, end_date date)
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
       Hotel               postgres    false    5                        1255    16880 :   get_available_rooms_by_date(date, date, character varying)    FUNCTION       CREATE FUNCTION "Hotel".get_available_rooms_by_date(check_start_date date, check_end_date date, p_city character varying DEFAULT NULL::character varying) RETURNS TABLE(city character varying, address character varying, room_number integer, start_date date, end_date date)
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
       Hotel               postgres    false    5            �            1255    16883 C   get_available_rooms_by_date(date, date, character varying, integer)    FUNCTION     #  CREATE FUNCTION "Hotel".get_available_rooms_by_date(check_start_date date, check_end_date date, p_city character varying DEFAULT NULL::character varying, p_min_capacity integer DEFAULT NULL::integer) RETURNS TABLE(city character varying, address character varying, room_number integer, capacity integer, amenities character varying[], price real, mountain_view boolean, sea_view boolean, extendable boolean)
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
       Hotel               postgres    false    5            �            1255    16837    update_number_of_hotels()    FUNCTION     �  CREATE FUNCTION "Hotel".update_number_of_hotels() RETURNS trigger
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
       Hotel               postgres    false    5            �            1255    16840    update_number_of_rooms()    FUNCTION     �  CREATE FUNCTION "Hotel".update_number_of_rooms() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- If a hotel is added, increase the count
    IF TG_OP = 'INSERT' THEN
        UPDATE "Hotel"."Hotel"
        SET number_rooms = (
            SELECT COUNT(*) FROM "Hotel"."Room" 
            WHERE "Hotel"."Hotel".address = NEW.address AND "Hotel"."Hotel".city = NEW.city
        )
        WHERE "Hotel"."Hotel".address = NEW.address AND "Hotel"."Hotel".city = NEW.city;

    -- If a hotel is deleted, decrease the count
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE "Hotel"."Hotel"
        SET number_rooms = (
            SELECT COUNT(*) FROM "Hotel"."Room" 
            WHERE "Hotel"."Hotel".address = OLD.address AND "Hotel"."Hotel".city = OLD.city
        )
        WHERE "Hotel"."Hotel".address = OLD.address AND "Hotel"."Hotel".city = OLD.city;
    END IF;

    RETURN NULL; -- No modification to the triggering row itself
END;
$$;
 0   DROP FUNCTION "Hotel".update_number_of_rooms();
       Hotel               postgres    false    5            �            1255    16792    update_renting_total_price()    FUNCTION     3  CREATE FUNCTION "Hotel".update_renting_total_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Renting"
    SET total_price = (
        SELECT SUM(r.price * (b.end_date - b.start_date)) 
        FROM "Rent_Room" br
        JOIN "Room" r ON br.room_number = r.room_number 
                   AND br.address = r.address 
                   AND br.city = r.city
        JOIN "Renting" b ON br.renting_ref = b.renting_ref  
        WHERE br.renting_ref = NEW.renting_ref
    )
    WHERE renting_ref = NEW.renting_ref;

    RETURN NEW;
END;
$$;
 4   DROP FUNCTION "Hotel".update_renting_total_price();
       Hotel               postgres    false    5            �            1255    16789    update_total_price()    FUNCTION     +  CREATE FUNCTION "Hotel".update_total_price() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    UPDATE "Booking"
    SET total_price = (
        SELECT SUM(r.price * (b.end_date - b.start_date)) 
        FROM "Book_Room" br
        JOIN "Room" r ON br.room_number = r.room_number 
                   AND br.address = r.address 
                   AND br.city = r.city
        JOIN "Booking" b ON br.booking_ref = b.booking_ref  
        WHERE br.booking_ref = NEW.booking_ref
    )
    WHERE booking_ref = NEW.booking_ref;

    RETURN NEW;
END;
$$;
 ,   DROP FUNCTION "Hotel".update_total_price();
       Hotel               postgres    false    5            �            1259    16696 	   Book_Room    TABLE     �   CREATE TABLE "Hotel"."Book_Room" (
    booking_ref integer NOT NULL,
    room_number integer NOT NULL,
    address character varying NOT NULL,
    city character varying NOT NULL
);
     DROP TABLE "Hotel"."Book_Room";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Book_Room"    ACL     7   GRANT ALL ON TABLE "Hotel"."Book_Room" TO remote_user;
          Hotel               postgres    false    231            �            1259    16681    Booking    TABLE     �   CREATE TABLE "Hotel"."Booking" (
    booking_ref integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_price real DEFAULT 0 NOT NULL,
    customer_id integer NOT NULL
);
    DROP TABLE "Hotel"."Booking";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Booking"    ACL     5   GRANT ALL ON TABLE "Hotel"."Booking" TO remote_user;
          Hotel               postgres    false    230            �            1259    16502    Chain    TABLE     �   CREATE TABLE "Hotel"."Chain" (
    name character varying NOT NULL,
    office_address character varying NOT NULL,
    number_of_hotels integer DEFAULT 0 NOT NULL
);
    DROP TABLE "Hotel"."Chain";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Chain"    ACL     3   GRANT ALL ON TABLE "Hotel"."Chain" TO remote_user;
          Hotel               postgres    false    217            �            1259    16523    Chain_Email_Inst    TABLE     w   CREATE TABLE "Hotel"."Chain_Email_Inst" (
    name character varying NOT NULL,
    email character varying NOT NULL
);
 '   DROP TABLE "Hotel"."Chain_Email_Inst";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Chain_Email_Inst"    ACL     >   GRANT ALL ON TABLE "Hotel"."Chain_Email_Inst" TO remote_user;
          Hotel               postgres    false    219            �            1259    16510    Chain_Phone_Inst    TABLE     s   CREATE TABLE "Hotel"."Chain_Phone_Inst" (
    name character varying NOT NULL,
    phone_number bigint NOT NULL
);
 '   DROP TABLE "Hotel"."Chain_Phone_Inst";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Chain_Phone_Inst"    ACL     >   GRANT ALL ON TABLE "Hotel"."Chain_Phone_Inst" TO remote_user;
          Hotel               postgres    false    218            �            1259    16713    Check_In    TABLE     x   CREATE TABLE "Hotel"."Check_In" (
    renting_ref integer NOT NULL,
    employee_id integer,
    booking_ref integer
);
    DROP TABLE "Hotel"."Check_In";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Check_In"    ACL     6   GRANT ALL ON TABLE "Hotel"."Check_In" TO remote_user;
          Hotel               postgres    false    232            �            1259    16654    Customer    TABLE     |  CREATE TABLE "Hotel"."Customer" (
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
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Customer"    ACL     6   GRANT ALL ON TABLE "Hotel"."Customer" TO remote_user;
          Hotel               postgres    false    228            �            1259    16582    Employee    TABLE     �  CREATE TABLE "Hotel"."Employee" (
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
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Employee"    ACL     6   GRANT ALL ON TABLE "Hotel"."Employee" TO remote_user;
          Hotel               postgres    false    222            �            1259    16599    Employee_Role    TABLE     p   CREATE TABLE "Hotel"."Employee_Role" (
    employee_id integer NOT NULL,
    role character varying NOT NULL
);
 $   DROP TABLE "Hotel"."Employee_Role";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Employee_Role"    ACL     ;   GRANT ALL ON TABLE "Hotel"."Employee_Role" TO remote_user;
          Hotel               postgres    false    223            �            1259    16535    Hotel    TABLE     .  CREATE TABLE "Hotel"."Hotel" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    name character varying NOT NULL,
    rating integer DEFAULT 0 NOT NULL,
    email character varying NOT NULL,
    number_rooms integer DEFAULT 0 NOT NULL,
    manager_id integer NOT NULL
);
    DROP TABLE "Hotel"."Hotel";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Hotel"    ACL     3   GRANT ALL ON TABLE "Hotel"."Hotel" TO remote_user;
          Hotel               postgres    false    220            �            1259    16549    Hotel_Phone_Inst    TABLE     �   CREATE TABLE "Hotel"."Hotel_Phone_Inst" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    phone_number bigint NOT NULL
);
 '   DROP TABLE "Hotel"."Hotel_Phone_Inst";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Hotel_Phone_Inst"    ACL     >   GRANT ALL ON TABLE "Hotel"."Hotel_Phone_Inst" TO remote_user;
          Hotel               postgres    false    221            �            1259    16664 	   Rent_Room    TABLE     �   CREATE TABLE "Hotel"."Rent_Room" (
    renting_ref integer NOT NULL,
    room_number integer NOT NULL,
    address character varying NOT NULL,
    city character varying NOT NULL
);
     DROP TABLE "Hotel"."Rent_Room";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Rent_Room"    ACL     7   GRANT ALL ON TABLE "Hotel"."Rent_Room" TO remote_user;
          Hotel               postgres    false    229            �            1259    16649    Renting    TABLE     �   CREATE TABLE "Hotel"."Renting" (
    renting_ref integer NOT NULL,
    start_date date NOT NULL,
    end_date date NOT NULL,
    total_price real DEFAULT 0 NOT NULL,
    customer_id integer
);
    DROP TABLE "Hotel"."Renting";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Renting"    ACL     5   GRANT ALL ON TABLE "Hotel"."Renting" TO remote_user;
          Hotel               postgres    false    227            �            1259    16611    Room    TABLE     �  CREATE TABLE "Hotel"."Room" (
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
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Room"    ACL     2   GRANT ALL ON TABLE "Hotel"."Room" TO remote_user;
          Hotel               postgres    false    224            �            1259    16625    Room_Amenities    TABLE     �   CREATE TABLE "Hotel"."Room_Amenities" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    room_number integer NOT NULL,
    amenity character varying NOT NULL
);
 %   DROP TABLE "Hotel"."Room_Amenities";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Room_Amenities"    ACL     <   GRANT ALL ON TABLE "Hotel"."Room_Amenities" TO remote_user;
          Hotel               postgres    false    225            �            1259    16637    Room_Issues    TABLE     �   CREATE TABLE "Hotel"."Room_Issues" (
    address character varying NOT NULL,
    city character varying NOT NULL,
    room_number integer NOT NULL,
    issue character varying NOT NULL
);
 "   DROP TABLE "Hotel"."Room_Issues";
       Hotel         heap r       postgres    false    5            �           0    0    TABLE "Room_Issues"    ACL     9   GRANT ALL ON TABLE "Hotel"."Room_Issues" TO remote_user;
          Hotel               postgres    false    226            �            1259    16854    available_rooms_per_area    VIEW     5  CREATE VIEW "Hotel".available_rooms_per_area AS
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
       Hotel       v       postgres    false    227    224    224    230    230    227    224    220    220    227    229    229    230    231    231    5            �           0    0    TABLE available_rooms_per_area    ACL     D   GRANT ALL ON TABLE "Hotel".available_rooms_per_area TO remote_user;
          Hotel               postgres    false    233            �            1259    16859    hotel_total_capacity    VIEW     �  CREATE VIEW "Hotel".hotel_total_capacity AS
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
       Hotel       v       postgres    false    220    224    224    224    224    220    220    5            �           0    0    TABLE hotel_total_capacity    ACL     @   GRANT ALL ON TABLE "Hotel".hotel_total_capacity TO remote_user;
          Hotel               postgres    false    234            �          0    16696 	   Book_Room 
   TABLE DATA           O   COPY "Hotel"."Book_Room" (booking_ref, room_number, address, city) FROM stdin;
    Hotel               postgres    false    231   �       �          0    16681    Booking 
   TABLE DATA           a   COPY "Hotel"."Booking" (booking_ref, start_date, end_date, total_price, customer_id) FROM stdin;
    Hotel               postgres    false    230   U�       �          0    16502    Chain 
   TABLE DATA           J   COPY "Hotel"."Chain" (name, office_address, number_of_hotels) FROM stdin;
    Hotel               postgres    false    217   ��       �          0    16523    Chain_Email_Inst 
   TABLE DATA           :   COPY "Hotel"."Chain_Email_Inst" (name, email) FROM stdin;
    Hotel               postgres    false    219   ��       �          0    16510    Chain_Phone_Inst 
   TABLE DATA           A   COPY "Hotel"."Chain_Phone_Inst" (name, phone_number) FROM stdin;
    Hotel               postgres    false    218   z�       �          0    16713    Check_In 
   TABLE DATA           L   COPY "Hotel"."Check_In" (renting_ref, employee_id, booking_ref) FROM stdin;
    Hotel               postgres    false    232   ��       �          0    16654    Customer 
   TABLE DATA           y   COPY "Hotel"."Customer" (customer_id, first_name, last_name, address, id_type, id_number, registration_date) FROM stdin;
    Hotel               postgres    false    228   !�       �          0    16582    Employee 
   TABLE DATA           �   COPY "Hotel"."Employee" (employee_id, first_name, last_name, address, id_type, id_number, hotel_address, hotel_city, manager_employee_id) FROM stdin;
    Hotel               postgres    false    222   ��       �          0    16599    Employee_Role 
   TABLE DATA           =   COPY "Hotel"."Employee_Role" (employee_id, role) FROM stdin;
    Hotel               postgres    false    223   ��       �          0    16535    Hotel 
   TABLE DATA           `   COPY "Hotel"."Hotel" (address, city, name, rating, email, number_rooms, manager_id) FROM stdin;
    Hotel               postgres    false    220   (�       �          0    16549    Hotel_Phone_Inst 
   TABLE DATA           J   COPY "Hotel"."Hotel_Phone_Inst" (address, city, phone_number) FROM stdin;
    Hotel               postgres    false    221   y�       �          0    16664 	   Rent_Room 
   TABLE DATA           O   COPY "Hotel"."Rent_Room" (renting_ref, room_number, address, city) FROM stdin;
    Hotel               postgres    false    229   ��       �          0    16649    Renting 
   TABLE DATA           a   COPY "Hotel"."Renting" (renting_ref, start_date, end_date, total_price, customer_id) FROM stdin;
    Hotel               postgres    false    227   ��       �          0    16611    Room 
   TABLE DATA           s   COPY "Hotel"."Room" (address, city, room_number, price, capacity, mountain_view, sea_view, extendable) FROM stdin;
    Hotel               postgres    false    224   *�       �          0    16625    Room_Amenities 
   TABLE DATA           P   COPY "Hotel"."Room_Amenities" (address, city, room_number, amenity) FROM stdin;
    Hotel               postgres    false    225   ��       �          0    16637    Room_Issues 
   TABLE DATA           K   COPY "Hotel"."Room_Issues" (address, city, room_number, issue) FROM stdin;
    Hotel               postgres    false    226   ��       �           2606    16702    Book_Room Book_Room_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Book_Room"
    ADD CONSTRAINT "Book_Room_pkey" PRIMARY KEY (booking_ref, address, city, room_number);
 G   ALTER TABLE ONLY "Hotel"."Book_Room" DROP CONSTRAINT "Book_Room_pkey";
       Hotel                 postgres    false    231    231    231    231            �           2606    16685    Booking Booking_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY "Hotel"."Booking"
    ADD CONSTRAINT "Booking_pkey" PRIMARY KEY (booking_ref);
 C   ALTER TABLE ONLY "Hotel"."Booking" DROP CONSTRAINT "Booking_pkey";
       Hotel                 postgres    false    230            �           2606    16529 &   Chain_Email_Inst Chain_Email_Inst_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst"
    ADD CONSTRAINT "Chain_Email_Inst_pkey" PRIMARY KEY (name, email);
 U   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst" DROP CONSTRAINT "Chain_Email_Inst_pkey";
       Hotel                 postgres    false    219    219            �           2606    16798 &   Chain_Phone_Inst Chain_Phone_Inst_pkey 
   CONSTRAINT     y   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst"
    ADD CONSTRAINT "Chain_Phone_Inst_pkey" PRIMARY KEY (name, phone_number);
 U   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst" DROP CONSTRAINT "Chain_Phone_Inst_pkey";
       Hotel                 postgres    false    218    218            �           2606    16509    Chain Chain_pkey 
   CONSTRAINT     U   ALTER TABLE ONLY "Hotel"."Chain"
    ADD CONSTRAINT "Chain_pkey" PRIMARY KEY (name);
 ?   ALTER TABLE ONLY "Hotel"."Chain" DROP CONSTRAINT "Chain_pkey";
       Hotel                 postgres    false    217            �           2606    16717    Check_In Check_In_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT "Check_In_pkey" PRIMARY KEY (renting_ref);
 E   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT "Check_In_pkey";
       Hotel                 postgres    false    232            �           2606    16661    Customer Customer_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY "Hotel"."Customer"
    ADD CONSTRAINT "Customer_pkey" PRIMARY KEY (customer_id);
 E   ALTER TABLE ONLY "Hotel"."Customer" DROP CONSTRAINT "Customer_pkey";
       Hotel                 postgres    false    228            �           2606    16605     Employee_Role Employee_Role_pkey 
   CONSTRAINT     r   ALTER TABLE ONLY "Hotel"."Employee_Role"
    ADD CONSTRAINT "Employee_Role_pkey" PRIMARY KEY (employee_id, role);
 O   ALTER TABLE ONLY "Hotel"."Employee_Role" DROP CONSTRAINT "Employee_Role_pkey";
       Hotel                 postgres    false    223    223            �           2606    16588    Employee Employee_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT "Employee_pkey" PRIMARY KEY (employee_id);
 E   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT "Employee_pkey";
       Hotel                 postgres    false    222            �           2606    16846 &   Hotel_Phone_Inst Hotel_Phone_Inst_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst"
    ADD CONSTRAINT "Hotel_Phone_Inst_pkey" PRIMARY KEY (city, address, phone_number);
 U   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst" DROP CONSTRAINT "Hotel_Phone_Inst_pkey";
       Hotel                 postgres    false    221    221    221            �           2606    16543    Hotel Hotel_pkey 
   CONSTRAINT     ^   ALTER TABLE ONLY "Hotel"."Hotel"
    ADD CONSTRAINT "Hotel_pkey" PRIMARY KEY (address, city);
 ?   ALTER TABLE ONLY "Hotel"."Hotel" DROP CONSTRAINT "Hotel_pkey";
       Hotel                 postgres    false    220    220            �           2606    16670    Rent_Room Renting_Room_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Rent_Room"
    ADD CONSTRAINT "Renting_Room_pkey" PRIMARY KEY (room_number, address, city, renting_ref);
 J   ALTER TABLE ONLY "Hotel"."Rent_Room" DROP CONSTRAINT "Renting_Room_pkey";
       Hotel                 postgres    false    229    229    229    229            �           2606    16653    Renting Renting_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY "Hotel"."Renting"
    ADD CONSTRAINT "Renting_pkey" PRIMARY KEY (renting_ref);
 C   ALTER TABLE ONLY "Hotel"."Renting" DROP CONSTRAINT "Renting_pkey";
       Hotel                 postgres    false    227            �           2606    16631 "   Room_Amenities Room_Amenities_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room_Amenities"
    ADD CONSTRAINT "Room_Amenities_pkey" PRIMARY KEY (address, city, room_number, amenity);
 Q   ALTER TABLE ONLY "Hotel"."Room_Amenities" DROP CONSTRAINT "Room_Amenities_pkey";
       Hotel                 postgres    false    225    225    225    225            �           2606    16643    Room_Issues Room_Issues_pkey 
   CONSTRAINT     ~   ALTER TABLE ONLY "Hotel"."Room_Issues"
    ADD CONSTRAINT "Room_Issues_pkey" PRIMARY KEY (address, city, room_number, issue);
 K   ALTER TABLE ONLY "Hotel"."Room_Issues" DROP CONSTRAINT "Room_Issues_pkey";
       Hotel                 postgres    false    226    226    226    226            �           2606    16619    Room Room_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY "Hotel"."Room"
    ADD CONSTRAINT "Room_pkey" PRIMARY KEY (address, city, room_number);
 =   ALTER TABLE ONLY "Hotel"."Room" DROP CONSTRAINT "Room_pkey";
       Hotel                 postgres    false    224    224    224            �           2606    16760    Booking booking_length    CHECK CONSTRAINT     s   ALTER TABLE "Hotel"."Booking"
    ADD CONSTRAINT booking_length CHECK (((end_date - start_date) <= 14)) NOT VALID;
 >   ALTER TABLE "Hotel"."Booking" DROP CONSTRAINT booking_length;
       Hotel               postgres    false    230    230    230    230            �           2606    16749    Booking booking_ref    CHECK CONSTRAINT     c   ALTER TABLE "Hotel"."Booking"
    ADD CONSTRAINT booking_ref CHECK ((booking_ref >= 0)) NOT VALID;
 ;   ALTER TABLE "Hotel"."Booking" DROP CONSTRAINT booking_ref;
       Hotel               postgres    false    230    230            �           2606    16751    Employee employee_id    CHECK CONSTRAINT     d   ALTER TABLE "Hotel"."Employee"
    ADD CONSTRAINT employee_id CHECK ((employee_id >= 0)) NOT VALID;
 <   ALTER TABLE "Hotel"."Employee" DROP CONSTRAINT employee_id;
       Hotel               postgres    false    222    222            �           2606    16752    Employee id_number    CHECK CONSTRAINT     `   ALTER TABLE "Hotel"."Employee"
    ADD CONSTRAINT id_number CHECK ((id_number >= 0)) NOT VALID;
 :   ALTER TABLE "Hotel"."Employee" DROP CONSTRAINT id_number;
       Hotel               postgres    false    222    222            �           2606    16663    Customer id_number_unique 
   CONSTRAINT     \   ALTER TABLE ONLY "Hotel"."Customer"
    ADD CONSTRAINT id_number_unique UNIQUE (id_number);
 F   ALTER TABLE ONLY "Hotel"."Customer" DROP CONSTRAINT id_number_unique;
       Hotel                 postgres    false    228            �           2606    16743    Chain number_hotels    CHECK CONSTRAINT     h   ALTER TABLE "Hotel"."Chain"
    ADD CONSTRAINT number_hotels CHECK ((number_of_hotels >= 0)) NOT VALID;
 ;   ALTER TABLE "Hotel"."Chain" DROP CONSTRAINT number_hotels;
       Hotel               postgres    false    217    217            �           2606    16745    Hotel number_rooms    CHECK CONSTRAINT     c   ALTER TABLE "Hotel"."Hotel"
    ADD CONSTRAINT number_rooms CHECK ((number_rooms >= 0)) NOT VALID;
 :   ALTER TABLE "Hotel"."Hotel" DROP CONSTRAINT number_rooms;
       Hotel               postgres    false    220    220            �           2606    16847    Hotel_Phone_Inst phone_number    CHECK CONSTRAINT     �   ALTER TABLE "Hotel"."Hotel_Phone_Inst"
    ADD CONSTRAINT phone_number CHECK (((phone_number >= 1111111111) AND (phone_number <= '9999999999'::bigint))) NOT VALID;
 E   ALTER TABLE "Hotel"."Hotel_Phone_Inst" DROP CONSTRAINT phone_number;
       Hotel               postgres    false    221    221            �           2606    16799 #   Chain_Phone_Inst phone_number_check    CHECK CONSTRAINT     �   ALTER TABLE "Hotel"."Chain_Phone_Inst"
    ADD CONSTRAINT phone_number_check CHECK (((phone_number >= 1111111111) AND (phone_number <= '9999999999'::bigint))) NOT VALID;
 K   ALTER TABLE "Hotel"."Chain_Phone_Inst" DROP CONSTRAINT phone_number_check;
       Hotel               postgres    false    218    218            �           2606    16744    Hotel rating    CHECK CONSTRAINT     k   ALTER TABLE "Hotel"."Hotel"
    ADD CONSTRAINT rating CHECK (((rating >= 1) AND (rating <= 5))) NOT VALID;
 4   ALTER TABLE "Hotel"."Hotel" DROP CONSTRAINT rating;
       Hotel               postgres    false    220    220            �           2606    16761    Renting renting_length    CHECK CONSTRAINT     s   ALTER TABLE "Hotel"."Renting"
    ADD CONSTRAINT renting_length CHECK (((end_date - start_date) <= 14)) NOT VALID;
 >   ALTER TABLE "Hotel"."Renting" DROP CONSTRAINT renting_length;
       Hotel               postgres    false    227    227    227    227            �           2606    16750    Renting renting_ref    CHECK CONSTRAINT     c   ALTER TABLE "Hotel"."Renting"
    ADD CONSTRAINT renting_ref CHECK ((renting_ref >= 0)) NOT VALID;
 ;   ALTER TABLE "Hotel"."Renting" DROP CONSTRAINT renting_ref;
       Hotel               postgres    false    227    227            �           2606    16754    Customer sin_unique 
   CONSTRAINT     V   ALTER TABLE ONLY "Hotel"."Customer"
    ADD CONSTRAINT sin_unique UNIQUE (id_number);
 @   ALTER TABLE ONLY "Hotel"."Customer" DROP CONSTRAINT sin_unique;
       Hotel                 postgres    false    228            �           2606    16756    Employee unique_id 
   CONSTRAINT     W   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT unique_id UNIQUE (employee_id);
 ?   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT unique_id;
       Hotel                 postgres    false    222            �           2606    16758    Employee unique_sin 
   CONSTRAINT     V   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT unique_sin UNIQUE (id_number);
 @   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT unique_sin;
       Hotel                 postgres    false    222            �           1259    16870    Idx_Book_Room_Composite    INDEX     h   CREATE INDEX "Idx_Book_Room_Composite" ON "Hotel"."Book_Room" USING btree (address, city, room_number);
 .   DROP INDEX "Hotel"."Idx_Book_Room_Composite";
       Hotel                 postgres    false    231    231    231            �           1259    16872    Idx_Booking_Dates    INDEX     Z   CREATE INDEX "Idx_Booking_Dates" ON "Hotel"."Booking" USING btree (start_date, end_date);
 (   DROP INDEX "Hotel"."Idx_Booking_Dates";
       Hotel                 postgres    false    230    230            �           1259    16871    Idx_Rent_Room_Composite    INDEX     h   CREATE INDEX "Idx_Rent_Room_Composite" ON "Hotel"."Rent_Room" USING btree (address, city, room_number);
 .   DROP INDEX "Hotel"."Idx_Rent_Room_Composite";
       Hotel                 postgres    false    229    229    229            �           1259    16873    Idx_Renting_Dates    INDEX     Z   CREATE INDEX "Idx_Renting_Dates" ON "Hotel"."Renting" USING btree (start_date, end_date);
 (   DROP INDEX "Hotel"."Idx_Renting_Dates";
       Hotel                 postgres    false    227    227            �           1259    16869    Idx_Room_Location    INDEX     P   CREATE INDEX "Idx_Room_Location" ON "Hotel"."Room" USING btree (address, city);
 (   DROP INDEX "Hotel"."Idx_Room_Location";
       Hotel                 postgres    false    224    224                        2620    16790 "   Book_Room book_room_insert_trigger    TRIGGER     �   CREATE TRIGGER book_room_insert_trigger AFTER INSERT OR DELETE ON "Hotel"."Book_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_total_price();
 >   DROP TRIGGER book_room_insert_trigger ON "Hotel"."Book_Room";
       Hotel               postgres    false    250    231                       2620    16767 $   Book_Room enforce_booking_room_limit    TRIGGER     �   CREATE TRIGGER enforce_booking_room_limit BEFORE INSERT ON "Hotel"."Book_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_booking_room_limit();
 @   DROP TRIGGER enforce_booking_room_limit ON "Hotel"."Book_Room";
       Hotel               postgres    false    231    236                       2620    16778 #   Book_Room enforce_no_double_booking    TRIGGER     �   CREATE TRIGGER enforce_no_double_booking BEFORE INSERT OR UPDATE ON "Hotel"."Book_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_booking_overlap();
 ?   DROP TRIGGER enforce_no_double_booking ON "Hotel"."Book_Room";
       Hotel               postgres    false    235    231            �           2620    16782 #   Rent_Room enforce_no_double_renting    TRIGGER     �   CREATE TRIGGER enforce_no_double_renting BEFORE INSERT OR UPDATE ON "Hotel"."Rent_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_renting_overlap();
 ?   DROP TRIGGER enforce_no_double_renting ON "Hotel"."Rent_Room";
       Hotel               postgres    false    251    229            �           2620    16844 $   Rent_Room enforce_renting_room_limit    TRIGGER     �   CREATE TRIGGER enforce_renting_room_limit BEFORE INSERT ON "Hotel"."Rent_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".check_renting_room_limit();
 @   DROP TRIGGER enforce_renting_room_limit ON "Hotel"."Rent_Room";
       Hotel               postgres    false    252    229            �           2620    16838    Hotel hotel_count_update    TRIGGER     �   CREATE TRIGGER hotel_count_update AFTER INSERT OR DELETE OR UPDATE ON "Hotel"."Hotel" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_number_of_hotels();
 4   DROP TRIGGER hotel_count_update ON "Hotel"."Hotel";
       Hotel               postgres    false    220    249            �           2620    16793 "   Rent_Room rent_room_insert_trigger    TRIGGER     �   CREATE TRIGGER rent_room_insert_trigger AFTER INSERT OR DELETE ON "Hotel"."Rent_Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_renting_total_price();
 >   DROP TRIGGER rent_room_insert_trigger ON "Hotel"."Rent_Room";
       Hotel               postgres    false    237    229            �           2620    16841    Room room_delete_trigger    TRIGGER     �   CREATE TRIGGER room_delete_trigger AFTER DELETE ON "Hotel"."Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_number_of_rooms();
 4   DROP TRIGGER room_delete_trigger ON "Hotel"."Room";
       Hotel               postgres    false    253    224            �           2620    16842    Room room_insert_trigger    TRIGGER     �   CREATE TRIGGER room_insert_trigger AFTER INSERT ON "Hotel"."Room" FOR EACH ROW EXECUTE FUNCTION "Hotel".update_number_of_rooms();
 4   DROP TRIGGER room_insert_trigger ON "Hotel"."Room";
       Hotel               postgres    false    253    224            �           2606    16517    Chain_Phone_Inst Name    FK CONSTRAINT     {   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst"
    ADD CONSTRAINT "Name" FOREIGN KEY (name) REFERENCES "Hotel"."Chain"(name);
 D   ALTER TABLE ONLY "Hotel"."Chain_Phone_Inst" DROP CONSTRAINT "Name";
       Hotel               postgres    false    217    4794    218            �           2606    16728    Check_In booking    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT booking FOREIGN KEY (booking_ref) REFERENCES "Hotel"."Booking"(booking_ref);
 =   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT booking;
       Hotel               postgres    false    230    4831    232            �           2606    16817    Book_Room booking    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Book_Room"
    ADD CONSTRAINT booking FOREIGN KEY (booking_ref) REFERENCES "Hotel"."Booking"(booking_ref) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 >   ALTER TABLE ONLY "Hotel"."Book_Room" DROP CONSTRAINT booking;
       Hotel               postgres    false    231    4831    230            �           2606    16686    Booking customer    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Booking"
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES "Hotel"."Customer"(customer_id);
 =   ALTER TABLE ONLY "Hotel"."Booking" DROP CONSTRAINT customer;
       Hotel               postgres    false    228    230    4822            �           2606    16691    Renting customer    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Renting"
    ADD CONSTRAINT customer FOREIGN KEY (customer_id) REFERENCES "Hotel"."Customer"(customer_id) NOT VALID;
 =   ALTER TABLE ONLY "Hotel"."Renting" DROP CONSTRAINT customer;
       Hotel               postgres    false    4822    228    227            �           2606    16606    Employee_Role employee    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Employee_Role"
    ADD CONSTRAINT employee FOREIGN KEY (employee_id) REFERENCES "Hotel"."Employee"(employee_id);
 C   ALTER TABLE ONLY "Hotel"."Employee_Role" DROP CONSTRAINT employee;
       Hotel               postgres    false    223    222    4804            �           2606    16723    Check_In employee    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT employee FOREIGN KEY (employee_id) REFERENCES "Hotel"."Employee"(employee_id);
 >   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT employee;
       Hotel               postgres    false    232    222    4804            �           2606    16556    Hotel_Phone_Inst hotel    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst"
    ADD CONSTRAINT hotel FOREIGN KEY (city, address) REFERENCES "Hotel"."Hotel"(city, address);
 C   ALTER TABLE ONLY "Hotel"."Hotel_Phone_Inst" DROP CONSTRAINT hotel;
       Hotel               postgres    false    220    220    221    221    4800            �           2606    16738 
   Room hotel    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room"
    ADD CONSTRAINT hotel FOREIGN KEY (address, city) REFERENCES "Hotel"."Hotel"(address, city) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 7   ALTER TABLE ONLY "Hotel"."Room" DROP CONSTRAINT hotel;
       Hotel               postgres    false    224    224    4800    220    220            �           2606    16827    Employee hotel    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT hotel FOREIGN KEY (hotel_address, hotel_city) REFERENCES "Hotel"."Hotel"(address, city) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 ;   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT hotel;
       Hotel               postgres    false    222    220    4800    222    220            �           2606    16822    Hotel manager    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel"
    ADD CONSTRAINT manager FOREIGN KEY (manager_id) REFERENCES "Hotel"."Employee"(employee_id) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 :   ALTER TABLE ONLY "Hotel"."Hotel" DROP CONSTRAINT manager;
       Hotel               postgres    false    222    220    4804            �           2606    16832    Employee manager    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Employee"
    ADD CONSTRAINT manager FOREIGN KEY (manager_employee_id) REFERENCES "Hotel"."Employee"(employee_id) DEFERRABLE INITIALLY DEFERRED NOT VALID;
 =   ALTER TABLE ONLY "Hotel"."Employee" DROP CONSTRAINT manager;
       Hotel               postgres    false    222    4804    222            �           2606    16530    Chain_Email_Inst name    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst"
    ADD CONSTRAINT name FOREIGN KEY (name) REFERENCES "Hotel"."Chain"(name) NOT VALID;
 B   ALTER TABLE ONLY "Hotel"."Chain_Email_Inst" DROP CONSTRAINT name;
       Hotel               postgres    false    219    4794    217            �           2606    16733 
   Hotel name    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Hotel"
    ADD CONSTRAINT name FOREIGN KEY (name) REFERENCES "Hotel"."Chain"(name) ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
 7   ALTER TABLE ONLY "Hotel"."Hotel" DROP CONSTRAINT name;
       Hotel               postgres    false    4794    217    220            �           2606    16671    Rent_Room renting    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Rent_Room"
    ADD CONSTRAINT renting FOREIGN KEY (renting_ref) REFERENCES "Hotel"."Renting"(renting_ref);
 >   ALTER TABLE ONLY "Hotel"."Rent_Room" DROP CONSTRAINT renting;
       Hotel               postgres    false    227    229    4820            �           2606    16718    Check_In renting    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Check_In"
    ADD CONSTRAINT renting FOREIGN KEY (renting_ref) REFERENCES "Hotel"."Renting"(renting_ref);
 =   ALTER TABLE ONLY "Hotel"."Check_In" DROP CONSTRAINT renting;
       Hotel               postgres    false    4820    232    227            �           2606    16632    Room_Amenities room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room_Amenities"
    ADD CONSTRAINT room FOREIGN KEY (address, city, room_number) REFERENCES "Hotel"."Room"(address, city, room_number);
 @   ALTER TABLE ONLY "Hotel"."Room_Amenities" DROP CONSTRAINT room;
       Hotel               postgres    false    225    224    225    224    224    4813    225            �           2606    16644    Room_Issues room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Room_Issues"
    ADD CONSTRAINT room FOREIGN KEY (address, city, room_number) REFERENCES "Hotel"."Room"(address, city, room_number);
 =   ALTER TABLE ONLY "Hotel"."Room_Issues" DROP CONSTRAINT room;
       Hotel               postgres    false    226    224    224    224    4813    226    226            �           2606    16676    Rent_Room room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Rent_Room"
    ADD CONSTRAINT room FOREIGN KEY (room_number, address, city) REFERENCES "Hotel"."Room"(room_number, address, city);
 ;   ALTER TABLE ONLY "Hotel"."Rent_Room" DROP CONSTRAINT room;
       Hotel               postgres    false    229    224    224    224    4813    229    229            �           2606    16708    Book_Room room    FK CONSTRAINT     �   ALTER TABLE ONLY "Hotel"."Book_Room"
    ADD CONSTRAINT room FOREIGN KEY (room_number, address, city) REFERENCES "Hotel"."Room"(room_number, address, city);
 ;   ALTER TABLE ONLY "Hotel"."Book_Room" DROP CONSTRAINT room;
       Hotel               postgres    false    231    231    231    4813    224    224    224            J           826    16501    DEFAULT PRIVILEGES FOR TABLES    DEFAULT ACL     O   ALTER DEFAULT PRIVILEGES FOR ROLE postgres GRANT ALL ON TABLES TO remote_user;
                        postgres    false            �   )   x�3�440�443P�HM,*.QO���N�K,I����� ��P      �   "   x�3�4202�50�5��3�9���+F��� lL�      �   f   x��1
�0E���@�vRP�`J
M��u���/T�dw�[$�p��Ya9g&��Q�jB��8���$��fR��������^���zeVy�ǣE�m�"      �   m   x�sJ-.Q�Ey�ť�E%I@~9DL/9?��	YQf^Z>�
�Ģ��������GfNI>��0,���Y\�$W�����LI�T��C��̃(����� �]I.      �   t   x�sJ-.Q�Ey���F�&\N�⦦�0q�Ģ����NKSc33S#�PL�#3�$�����̜+(1%��8j������G~NfJb��gX������+F��� �)      �      x�3�4�4����� �X      �   n   x�3�JL�H,��tJL��M�L-�45Tp��H�Sp,K���LN�+N�44261�4202�50�5��2�t�O��Mv��K�I�+����p{�q����Z���p��qqq ���      �   K   x�3��������,��442V.)JM-�R���~ QS3sKNC3��Ģ����JN�ļĒD�?�=... 3��      �      x�3�T��/I�Q�M�KLO-����� H��      �   A   x�343P�HM,*.QO���N�K,I�tJ�DjQ�g6X�!	(P�K���4�4����� u�      �   6   x�343P�HM,*.QO���N�K,I�4616147153�2Ī���� F��� ��p      �   )   x�3�440�443P�HM,*.QO���N�K,I����� ��P      �   "   x�3�4202�50�5��3�9���+F��� lL�      �   K   x�343P�HM,*.QO���N�K,I�440�43�3�4�L�.Cʌ�SfL�2┙r� ����q��qqq @y1�      �   ,   x�343P�HM,*.QO���N�K,I�440��������� ��	�      �   5   x�343P�HM,*.QO���N�K,I�440�t*��N�S(���I-����� 9_1     