import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { leadsService, type LeadFormData, type FollowupData } from "@/services/leads.service";

export function useLeads(params?: {
  page?: number;
  page_size?: number;
  search?: string;
  lead_status?: string;
  lead_source?: string;
  assigned_to?: number;
}) {
  return useQuery({
    queryKey: ["leads", params],
    queryFn: () => leadsService.list(params),
  });
}

export function useLead(id: number) {
  return useQuery({
    queryKey: ["lead", id],
    queryFn: () => leadsService.get(id),
    enabled: !!id,
  });
}

export function useCreateLead() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: LeadFormData) => leadsService.create(data),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["leads"] }),
  });
}

export function useUpdateLead(id: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: Partial<LeadFormData>) => leadsService.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["leads"] });
      queryClient.invalidateQueries({ queryKey: ["lead", id] });
    },
  });
}

export function useDeleteLead() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => leadsService.delete(id),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["leads"] }),
  });
}

export function useConvertLead() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: number) => leadsService.convert(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["leads"] });
    },
  });
}

export function useLeadFollowups(leadId: number) {
  return useQuery({
    queryKey: ["lead", leadId, "followups"],
    queryFn: () => leadsService.listFollowups(leadId),
    enabled: !!leadId,
  });
}

export function useAddFollowup(leadId: number) {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: FollowupData) => leadsService.addFollowup(leadId, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["lead", leadId, "followups"] });
      queryClient.invalidateQueries({ queryKey: ["lead", leadId] });
    },
  });
}
