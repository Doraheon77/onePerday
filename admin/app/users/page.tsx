'use client'
import { useEffect, useState } from 'react'
import { api } from '../../lib/api'

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(false)

  const fetchUsers = async () => {
    setLoading(true)
    const data = await api.getUsers(search)
    setUsers(data)
    setLoading(false)
  }

  useEffect(() => {
    fetchUsers()
  }, [])

  const handleDelete = async (id: string) => {
    if (!confirm('정말 삭제하시겠습니까?')) return
    await api.deleteUser(id)
    setUsers(users.filter(u => u.id !== id))
  }

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-6">유저 관리</h1>
      <div className="flex gap-2 mb-4">
        <input
          className="border p-2 flex-1 rounded"
          placeholder="이름 또는 이메일 검색"
          value={search}
          onChange={e => setSearch(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && fetchUsers()}
        />
        <button
          onClick={fetchUsers}
          className="bg-blue-500 text-white px-4 py-2 rounded"
        >
          검색
        </button>
      </div>

      <p className="text-sm text-gray-500 mb-2">총 {users.length}명</p>

      {loading ? (
        <p>로딩 중...</p>
      ) : (
        <table className="w-full border-collapse border">
          <thead>
            <tr className="bg-gray-100">
              <th className="border p-2 text-left">이름</th>
              <th className="border p-2 text-left">성별</th>
              <th className="border p-2 text-left">출생연도</th>
              <th className="border p-2 text-left">이메일</th>              
              <th className="border p-2 text-left">가입일</th>
              <th className="border p-2">삭제</th>
            </tr>
          </thead>
          <tbody>
            {users.map(user => (
              <tr key={user.id} className="border-t">
                <td className="border p-2">{user.name ?? '-'}</td>
                <td className="border p-2">{user.gender ?? '-'}</td>
                <td className="border p-2">{user.birth_year ?? '-'}</td>
                <td className="border p-2">{user.users?.email ?? '-'}</td>
                <td className="border p-2">
                  {new Date(user.created_at).toLocaleDateString('ko-KR')}
                </td>
                <td className="border p-2 text-center">
                  <button
                    onClick={() => handleDelete(user.id)}
                    className="bg-red-500 text-white px-3 py-1 rounded"
                  >
                    삭제
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}