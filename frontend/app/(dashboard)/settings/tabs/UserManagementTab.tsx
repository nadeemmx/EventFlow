"use client"

import { useState, useEffect } from "react"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Badge } from "@/components/ui/badge"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger, DialogFooter } from "@/components/ui/dialog"
import { LoadingState } from "@/components/common/LoadingState"
import { ErrorState } from "@/components/common/ErrorState"
import { useToast } from "@/components/ui/toast"
import { getUsers, createUser, updateUser, deleteUser, activateUser, deactivateUser, getRoles } from "@/services/settings.service"
import type { SettingsUser, RoleChoice } from "@/types/settings"
import { Plus, Pencil, Trash2, Ban, CheckCircle } from "lucide-react"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"

interface UserFormData {
  full_name: string
  email: string
  mobile: string
  role: string
  password?: string
}

const emptyForm: UserFormData = {
  full_name: "",
  email: "",
  mobile: "",
  role: "",
  password: "",
}

export default function UserManagementTab() {
  const { toast } = useToast()
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [users, setUsers] = useState<SettingsUser[]>([])
  const [roles, setRoles] = useState<RoleChoice[]>([])
  const [showModal, setShowModal] = useState(false)
  const [editId, setEditId] = useState<number | null>(null)
  const [saving, setSaving] = useState(false)
  const [form, setForm] = useState<UserFormData>(emptyForm)

  useEffect(() => {
    loadData()
  }, [])

  async function loadData() {
    setLoading(true)
    setError(null)
    try {
      const [usersRes, rolesRes] = await Promise.all([getUsers(), getRoles()])
      if (usersRes.success) setUsers(usersRes.data)
      else setError(usersRes.message)
      if (rolesRes.success) setRoles(rolesRes.data)
    } catch (err: any) {
      setError(err.message || "Failed to load users")
    } finally {
      setLoading(false)
    }
  }

  function openCreate() {
    setEditId(null)
    setForm(emptyForm)
    setShowModal(true)
  }

  function openEdit(user: SettingsUser) {
    setEditId(user.id)
    setForm({
      full_name: user.full_name,
      email: user.email,
      mobile: user.mobile,
      role: user.role,
      password: "",
    })
    setShowModal(true)
  }

  function updateField(field: keyof UserFormData, value: string) {
    setForm(prev => ({ ...prev, [field]: value }))
  }

  function validate(): boolean {
    if (!form.full_name.trim()) {
      toast({ title: "Validation Error", description: "Full name is required.", variant: "destructive" })
      return false
    }
    if (!form.email.trim() || !/\S+@\S+\.\S+/.test(form.email)) {
      toast({ title: "Validation Error", description: "A valid email is required.", variant: "destructive" })
      return false
    }
    if (!form.role) {
      toast({ title: "Validation Error", description: "Role is required.", variant: "destructive" })
      return false
    }
    if (!editId && !form.password) {
      toast({ title: "Validation Error", description: "Password is required for new users.", variant: "destructive" })
      return false
    }
    return true
  }

  async function handleSave() {
    if (!validate()) return
    setSaving(true)
    try {
      const res = editId
        ? await updateUser(editId, { full_name: form.full_name, email: form.email, mobile: form.mobile, role: form.role })
        : await createUser(form)
      if (res.success) {
        toast({ title: editId ? "User updated" : "User created", description: `User has been ${editId ? "updated" : "created"} successfully.` })
        setShowModal(false)
        loadData()
      } else {
        toast({ title: "Error", description: res.message, variant: "destructive" })
      }
    } catch (err: any) {
      toast({ title: "Error", description: err.message, variant: "destructive" })
    } finally {
      setSaving(false)
    }
  }

  async function handleDelete(user: SettingsUser) {
    if (!confirm(`Are you sure you want to delete ${user.full_name}?`)) return
    try {
      const res = await deleteUser(user.id)
      if (res.success) {
        toast({ title: "User deleted", description: `${user.full_name} has been deleted.` })
        loadData()
      } else {
        toast({ title: "Error", description: res.message, variant: "destructive" })
      }
    } catch (err: any) {
      toast({ title: "Error", description: err.message, variant: "destructive" })
    }
  }

  async function handleToggleActive(user: SettingsUser) {
    try {
      const res = user.is_active ? await deactivateUser(user.id) : await activateUser(user.id)
      if (res.success) {
        toast({ title: user.is_active ? "User deactivated" : "User activated", description: `${user.full_name} has been ${user.is_active ? "deactivated" : "activated"}.` })
        loadData()
      } else {
        toast({ title: "Error", description: res.message, variant: "destructive" })
      }
    } catch (err: any) {
      toast({ title: "Error", description: err.message, variant: "destructive" })
    }
  }

  if (loading) return <LoadingState type="page" />
  if (error) return <ErrorState message={error} onRetry={loadData} />

  return (
    <Card>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>User Management</CardTitle>
        <Dialog open={showModal} onOpenChange={setShowModal}>
          <DialogTrigger asChild>
            <Button size="sm" onClick={openCreate}>
              <Plus className="h-4 w-4 mr-1" /> Add User
            </Button>
          </DialogTrigger>
          <DialogContent>
            <DialogHeader>
              <DialogTitle>{editId ? "Edit User" : "Add User"}</DialogTitle>
            </DialogHeader>
            <div className="space-y-4 py-4">
              <div className="space-y-2">
                <Label htmlFor="mfull_name">Full Name *</Label>
                <Input id="mfull_name" value={form.full_name} onChange={e => updateField("full_name", e.target.value)} placeholder="Full name" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="memail">Email *</Label>
                <Input id="memail" type="email" value={form.email} onChange={e => updateField("email", e.target.value)} placeholder="email@example.com" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="mmobile">Mobile</Label>
                <Input id="mmobile" value={form.mobile} onChange={e => updateField("mobile", e.target.value)} placeholder="+1 234 567 8900" />
              </div>
              <div className="space-y-2">
                <Label htmlFor="mrole">Role *</Label>
                <Select value={form.role} onValueChange={v => updateField("role", v)}>
                  <SelectTrigger id="mrole">
                    <SelectValue placeholder="Select role" />
                  </SelectTrigger>
                  <SelectContent>
                    {roles.map(r => (
                      <SelectItem key={r.value} value={r.value}>{r.label}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-2">
                <Label htmlFor="mpassword">{editId ? "New Password (leave blank to keep)" : "Password *"}</Label>
                <Input id="mpassword" type="password" value={form.password || ""} onChange={e => updateField("password", e.target.value)} placeholder="Password" />
              </div>
            </div>
            <DialogFooter>
              <Button variant="outline" onClick={() => setShowModal(false)}>Cancel</Button>
              <Button onClick={handleSave} disabled={saving}>
                {saving ? "Saving..." : (editId ? "Update" : "Create")}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </CardHeader>
      <CardContent>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Name</TableHead>
              <TableHead>Email</TableHead>
              <TableHead>Role</TableHead>
              <TableHead>Status</TableHead>
              <TableHead>Last Login</TableHead>
              <TableHead className="text-right">Actions</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {users.length === 0 ? (
              <TableRow>
                <TableCell colSpan={6} className="text-center text-muted-foreground py-8">No users found</TableCell>
              </TableRow>
            ) : (
              users.map(user => (
                <TableRow key={user.id}>
                  <TableCell className="font-medium">{user.full_name}</TableCell>
                  <TableCell>{user.email}</TableCell>
                  <TableCell>
                    <Badge variant="secondary">{user.role}</Badge>
                  </TableCell>
                  <TableCell>
                    <Badge variant={user.is_active ? "success" : "destructive"}>
                      {user.is_active ? "Active" : "Inactive"}
                    </Badge>
                  </TableCell>
                  <TableCell className="text-muted-foreground">
                    {user.last_login ? new Date(user.last_login).toLocaleDateString() : "Never"}
                  </TableCell>
                  <TableCell className="text-right">
                    <div className="flex items-center justify-end gap-1">
                      <Button variant="ghost" size="icon" onClick={() => openEdit(user)} title="Edit">
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleToggleActive(user)} title={user.is_active ? "Deactivate" : "Activate"}>
                        {user.is_active ? <Ban className="h-4 w-4 text-amber-500" /> : <CheckCircle className="h-4 w-4 text-green-500" />}
                      </Button>
                      <Button variant="ghost" size="icon" onClick={() => handleDelete(user)} title="Delete">
                        <Trash2 className="h-4 w-4 text-destructive" />
                      </Button>
                    </div>
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
