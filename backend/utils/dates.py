from datetime import datetime, date
import pytz


KOLKATA_TZ = pytz.timezone("Asia/Kolkata")


def now_kolkata():
    return datetime.now(KOLKATA_TZ)


def today_kolkata():
    return now_kolkata().date()


def format_date_kolkata(dt: date):
    return dt.strftime("%d-%b-%Y")


def format_datetime_kolkata(dt: datetime):
    if dt.tzinfo is None:
        dt = pytz.utc.localize(dt)
    return dt.astimezone(KOLKATA_TZ).strftime("%d-%b-%Y %I:%M %p")
