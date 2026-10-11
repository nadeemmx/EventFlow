import axios from "axios";

const apiClient = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1",
  headers: { "Content-Type": "application/json" },
  timeout: 30000, // 30 second default timeout
});

apiClient.interceptors.request.use((config) => {
  if (typeof window !== "undefined") {
    const token = localStorage.getItem("access_token");
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

interface PaginationMeta {
  page: number;
  page_size: number;
  total_records: number;
  total_pages: number;
}

/**
 * The API mixes two response shapes:
 * - envelope:  { success, message, data, pagination? }
 * - DRF/plain: { count, next, previous, results } for list endpoints and bare
 *              objects for retrieve/create/update on a few viewsets.
 *
 * The app is written against the envelope shape, so every successful JSON body
 * is normalized to it here. Original DRF keys are preserved so callers that
 * read `results`/`count` keep working.
 */
function normalizeResponseBody(body: unknown, params: unknown): unknown {
  if (typeof Blob !== "undefined" && body instanceof Blob) return body;
  if (body instanceof ArrayBuffer) return body;

  const isPlainObject =
    typeof body === "object" && body !== null && !Array.isArray(body);
  if (!isPlainObject && !Array.isArray(body)) return body;

  const record = body as Record<string, unknown>;
  if ("success" in record) return body;

  if (Array.isArray(record.results) && typeof record.count === "number") {
    const query = (params ?? {}) as Record<string, unknown>;
    const page = Number(query.page) || 1;
    const pageSize = Number(query.page_size) || 20;
    const totalRecords = record.count;
    const pagination: PaginationMeta = {
      page,
      page_size: pageSize,
      total_records: totalRecords,
      total_pages: Math.max(1, Math.ceil(totalRecords / pageSize)),
    };
    return {
      ...record,
      success: true,
      message: "Operation successful",
      data: record.results,
      pagination,
    };
  }

  return { success: true, message: "Operation successful", data: body };
}

apiClient.interceptors.response.use(
  (res) => {
    res.data = normalizeResponseBody(res.data, res.config?.params);
    return res;
  },
  async (error) => {
    if (error.response?.status === 401 && typeof window !== "undefined") {
      const refreshToken = localStorage.getItem("refresh_token");
      if (refreshToken && !error.config._retry) {
        error.config._retry = true;
        try {
          const { data } = await axios.post(
            `${apiClient.defaults.baseURL}/auth/refresh/`,
            { refresh_token: refreshToken }
          );
          localStorage.setItem("access_token", data.data.access_token);
          localStorage.setItem("refresh_token", data.data.refresh_token);
          error.config.headers.Authorization = `Bearer ${data.data.access_token}`;
          return apiClient(error.config);
        } catch {
          localStorage.clear();
          window.location.href = "/login";
        }
      }
    }
    return Promise.reject(error);
  }
);

export default apiClient;
