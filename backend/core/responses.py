from rest_framework.response import Response


def ok(data=None, message="Operation successful", status=200):
    body = {"success": True, "message": message, "data": data}
    return Response(body, status=status)


def error(message="Operation failed", errors=None, status=400):
    body = {"success": False, "message": message, "errors": errors or {}}
    return Response(body, status=status)


def paginated(data, paginator):
    return Response(
        {
            "success": True,
            "data": data,
            "pagination": {
                "page": paginator.page.number,
                "page_size": paginator.page.paginator.per_page,
                "total_records": paginator.page.paginator.count,
                "total_pages": paginator.page.paginator.num_pages,
            },
        }
    )
