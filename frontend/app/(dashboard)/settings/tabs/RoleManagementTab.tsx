"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { getRoles } from "@/services/settings.service"
import type { RoleChoice } from "@/types/settings"

export default function RoleManagementTab() {
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [roles, setRoles] = useState<RoleChoice[]>([])

  useEffect(() => {
    loadRoles()
  }, [])

  async function loadRoles() {
    setLoading(true)
    setError(null)
    try {
      const res = await getRoles()
      if (res.success) setRoles(res.data)
      else setError(res.message)
    } catch (err: any) {
      setError(err.message || "Failed to load roles")
    } finally {
      setLoading(false)
    }
  }

  if (loading) return <LoadingState type="page" />
  if (error) return <ErrorState message={error} onRetry={loadRoles} />

  return (
    <Card>
      <CardHeader>
        <CardTitle>Roles</CardTitle>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Role</TableHead>
              <TableHead>Value</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {roles.length === 0 ? (
              <TableRow>
                <TableCell colSpan={2} className="text-center text-muted-foreground py-8">No roles available</TableCell>
              </TableRow>
            ) : (
              roles.map(role => (
                <TableRow key={role.value}>
                  <TableCell className="font-medium">{role.label}</TableCell>
                  <TableCell>
                    <Badge variant="secondary">{role.value}</Badge>
                  </TableCell>
                </TableRow>
              ))
            )}
          </TableBody>
        </Table>
      </CardContent>
    </Card>
  )
}
