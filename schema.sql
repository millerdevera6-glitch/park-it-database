--
-- PostgreSQL database dump
--

\restrict vUFRKovzrO9uvf3g2rPr5aqrABy4cj7huYG9R0M5JtlRyBdqKh1S7dEmRlTAh5a

-- Dumped from database version 18.6
-- Dumped by pg_dump version 18.6

-- Started on 2026-11-03 02:16:05

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 220 (class 1259 OID 16389)
-- Name: parking_zone; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.parking_zone (
    zone_id integer NOT NULL,
    zone_name character varying(50) NOT NULL,
    max_capacity integer NOT NULL,
    current_active_count integer DEFAULT 0 NOT NULL,
    CONSTRAINT parking_zone_check CHECK ((current_active_count <= max_capacity))
);


ALTER TABLE public.parking_zone OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16388)
-- Name: parking_zone_zone_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.parking_zone_zone_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.parking_zone_zone_id_seq OWNER TO postgres;

--
-- TOC entry 5059 (class 0 OID 0)
-- Dependencies: 219
-- Name: parking_zone_zone_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.parking_zone_zone_id_seq OWNED BY public.parking_zone.zone_id;


--
-- TOC entry 228 (class 1259 OID 16454)
-- Name: payment; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payment (
    payment_id integer NOT NULL,
    transaction_id integer NOT NULL,
    amount numeric(10,2) NOT NULL,
    payment_method character varying(50) NOT NULL,
    payment_time timestamp without time zone NOT NULL,
    CONSTRAINT payment_amount_check CHECK ((amount >= (0)::numeric))
);


ALTER TABLE public.payment OWNER TO postgres;

--
-- TOC entry 227 (class 1259 OID 16453)
-- Name: payment_payment_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.payment_payment_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.payment_payment_id_seq OWNER TO postgres;

--
-- TOC entry 5060 (class 0 OID 0)
-- Dependencies: 227
-- Name: payment_payment_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.payment_payment_id_seq OWNED BY public.payment.payment_id;


--
-- TOC entry 224 (class 1259 OID 16416)
-- Name: staff_user; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.staff_user (
    user_id integer NOT NULL,
    username character varying(50) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role character varying(20) NOT NULL
);


ALTER TABLE public.staff_user OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16415)
-- Name: staff_user_user_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.staff_user_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.staff_user_user_id_seq OWNER TO postgres;

--
-- TOC entry 5061 (class 0 OID 0)
-- Dependencies: 223
-- Name: staff_user_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.staff_user_user_id_seq OWNED BY public.staff_user.user_id;


--
-- TOC entry 226 (class 1259 OID 16429)
-- Name: transaction; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction (
    transaction_id integer NOT NULL,
    vehicle_id integer NOT NULL,
    zone_id integer NOT NULL,
    entry_time timestamp without time zone NOT NULL,
    exit_time timestamp without time zone,
    status character varying(20) DEFAULT 'Active'::character varying NOT NULL,
    is_lost_ticket boolean DEFAULT false NOT NULL
);


ALTER TABLE public.transaction OWNER TO postgres;

--
-- TOC entry 225 (class 1259 OID 16428)
-- Name: transaction_transaction_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_transaction_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_transaction_id_seq OWNER TO postgres;

--
-- TOC entry 5062 (class 0 OID 0)
-- Dependencies: 225
-- Name: transaction_transaction_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_transaction_id_seq OWNED BY public.transaction.transaction_id;


--
-- TOC entry 222 (class 1259 OID 16404)
-- Name: vehicle; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle (
    vehicle_id integer NOT NULL,
    license_plate character varying(20) NOT NULL,
    vehicle_type character varying(50) NOT NULL
);


ALTER TABLE public.vehicle OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16403)
-- Name: vehicle_vehicle_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_vehicle_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_vehicle_id_seq OWNER TO postgres;

--
-- TOC entry 5063 (class 0 OID 0)
-- Dependencies: 221
-- Name: vehicle_vehicle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_vehicle_id_seq OWNED BY public.vehicle.vehicle_id;


--
-- TOC entry 4876 (class 2604 OID 16392)
-- Name: parking_zone zone_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_zone ALTER COLUMN zone_id SET DEFAULT nextval('public.parking_zone_zone_id_seq'::regclass);


--
-- TOC entry 4883 (class 2604 OID 16457)
-- Name: payment payment_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment ALTER COLUMN payment_id SET DEFAULT nextval('public.payment_payment_id_seq'::regclass);


--
-- TOC entry 4879 (class 2604 OID 16419)
-- Name: staff_user user_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_user ALTER COLUMN user_id SET DEFAULT nextval('public.staff_user_user_id_seq'::regclass);


--
-- TOC entry 4880 (class 2604 OID 16432)
-- Name: transaction transaction_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction ALTER COLUMN transaction_id SET DEFAULT nextval('public.transaction_transaction_id_seq'::regclass);


--
-- TOC entry 4878 (class 2604 OID 16407)
-- Name: vehicle vehicle_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle ALTER COLUMN vehicle_id SET DEFAULT nextval('public.vehicle_vehicle_id_seq'::regclass);


--
-- TOC entry 4887 (class 2606 OID 16400)
-- Name: parking_zone parking_zone_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_zone
    ADD CONSTRAINT parking_zone_pkey PRIMARY KEY (zone_id);


--
-- TOC entry 4889 (class 2606 OID 16402)
-- Name: parking_zone parking_zone_zone_name_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.parking_zone
    ADD CONSTRAINT parking_zone_zone_name_key UNIQUE (zone_name);


--
-- TOC entry 4901 (class 2606 OID 16465)
-- Name: payment payment_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_pkey PRIMARY KEY (payment_id);


--
-- TOC entry 4903 (class 2606 OID 16467)
-- Name: payment payment_transaction_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_transaction_id_key UNIQUE (transaction_id);


--
-- TOC entry 4895 (class 2606 OID 16425)
-- Name: staff_user staff_user_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_user
    ADD CONSTRAINT staff_user_pkey PRIMARY KEY (user_id);


--
-- TOC entry 4897 (class 2606 OID 16427)
-- Name: staff_user staff_user_username_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.staff_user
    ADD CONSTRAINT staff_user_username_key UNIQUE (username);


--
-- TOC entry 4899 (class 2606 OID 16442)
-- Name: transaction transaction_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_pkey PRIMARY KEY (transaction_id);


--
-- TOC entry 4891 (class 2606 OID 16414)
-- Name: vehicle vehicle_license_plate_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle
    ADD CONSTRAINT vehicle_license_plate_key UNIQUE (license_plate);


--
-- TOC entry 4893 (class 2606 OID 16412)
-- Name: vehicle vehicle_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle
    ADD CONSTRAINT vehicle_pkey PRIMARY KEY (vehicle_id);


--
-- TOC entry 4906 (class 2606 OID 16468)
-- Name: payment payment_transaction_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payment
    ADD CONSTRAINT payment_transaction_id_fkey FOREIGN KEY (transaction_id) REFERENCES public.transaction(transaction_id);


--
-- TOC entry 4904 (class 2606 OID 16443)
-- Name: transaction transaction_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicle(vehicle_id);


--
-- TOC entry 4905 (class 2606 OID 16448)
-- Name: transaction transaction_zone_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction
    ADD CONSTRAINT transaction_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.parking_zone(zone_id);


-- Completed on 2026-11-03 02:16:05

--
-- PostgreSQL database dump complete
--

\unrestrict vUFRKovzrO9uvf3g2rPr5aqrABy4cj7huYG9R0M5JtlRyBdqKh1S7dEmRlTAh5a

