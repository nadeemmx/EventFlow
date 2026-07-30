import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { bookingsService, type BookingFormData } from "@/services/bookings.service";

export function useBookings(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
  venue?: number;
  event_type?: string;
}) {
  return useQuery({
    queryKey: ["bookings", params],
    queryFn: () => bookingsService.list(params),
  });
}

export function useBooking(id: number) {
  return useQuery({
    queryKey: ["booking", id],
    queryFn: () => bookingsService.get(id),
    enabled: !!id,
  });
}

export function useCreateBooking() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: BookingFormData) => bookingsService.create(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useUpdateBooking(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<BookingFormData>) => bookingsService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
      queryClient.invalidateQueries({ queryKey: ["booking", id] });
    },
  });
}

export function useDeleteBooking() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => bookingsService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["bookings"] }),
  });
}

export function useConfirmBooking() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => bookingsService.confirm(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useCancelBooking() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, remarks }: { id: number; remarks?: string }) =>
      bookingsService.cancel(id, remarks),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useBookingTimeline(id: number) {
  return useQuery({
    queryKey: ["booking", id, "timeline"],
    queryFn: () => bookingsService.timeline(id),
    enabled: !!id,
  });
}

export function useCalendarBookings(params: { month: number; year: number; venue?: number }) {
  return useQuery({
    queryKey: ["bookings", "calendar", params],
    queryFn: () => bookingsService.calendar(params),
  });
}

export function useMarkBookingInProgress() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => bookingsService.markInProgress(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useMarkBookingCompleted() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => bookingsService.markCompleted(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["bookings"] });
    },
  });
}

export function useBookingOutstanding(id: number) {
  return useQuery({
    queryKey: ["booking", id, "outstanding"],
    queryFn: () => bookingsService.outstanding(id),
    enabled: !!id,
  });
}
