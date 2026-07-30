import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { venuesService, type VenueFormData } from "@/services/venues.service";

export function useVenues(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  status?: string;
  venue_type?: string;
}) {
  return useQuery({
    queryKey: ["venues", params],
    queryFn: () => venuesService.list(params),
  });
}

export function useVenue(id: number) {
  return useQuery({
    queryKey: ["venue", id],
    queryFn: () => venuesService.get(id),
    enabled: !!id,
  });
}

export function useCreateVenue() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: VenueFormData) => venuesService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["venues"] }),
  });
}

export function useUpdateVenue(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<VenueFormData>) => venuesService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["venues"] });
      queryClient.invalidateQueries({ queryKey: ["venue", id] });
    },
  });
}

export function useDeleteVenue() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => venuesService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["venues"] }),
  });
}

export function useUploadVenueImage() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: ({ id, file }: { id: number; file: File }) => venuesService.uploadImage(id, file),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["venues"] });
    },
  });
}
