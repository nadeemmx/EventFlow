import uuid
import os


def upload_path(instance, filename):
    ext = filename.split(".")[-1]
    unique_name = f"{uuid.uuid4().hex}.{ext}"
    if hasattr(instance, "venue"):
        return os.path.join("venues", unique_name)
    if hasattr(instance, "customer"):
        return os.path.join("customers", unique_name)
    return os.path.join("uploads", unique_name)
