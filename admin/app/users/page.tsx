'use client'
import { useEffect, useState } from 'react'
import { api } from '../../lib/api'

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([])
  const [search, setSearch] = useState('')
  const [loading, setLoading] = useState(false)
  const [editUser, setEditUser] = useState<any>(null)

  const fetchUsers = async () => {
    setLoading(true)
    const data = await api.getUsers(search)
    setUsers(data)
    setLoading(false)
  }

  useEffect(() => { fetchUsers() }, [])

  const handleDelete = async (id: string) => {
    if (!confirm('정말 삭제하시겠습니까?')) return
    await api.deleteUser(id)
    setUsers(users.filter(u => u.id !== id))
  }

  const handleUpdate = async () => {
    await api.updateUser(editUser.id, {
      name: editUser.name,
      gender: editUser.gender,
      birth_year: editUser.birth_year,
    })
    setEditUser(null)
    fetchUsers()
  }

  const btnStyle = (color: string, bg: string, border: string) => ({
    backgroundColor: bg, color, border: `1px solid ${border}`,
    borderRadius: '8px', padding: '6px 14px', fontSize: '13px',
    cursor: 'pointer', fontWeight: 600,
  })

  return (
    <div>
      <h1 style={{ fontSize: '22px', fontWeight: 700, color: '#2d8a5e', marginBottom: '1.5rem' }}>유저 관리</h1>

      <div style={{ display: 'flex', gap: '8px', marginBottom: '1rem' }}>
        <input
          style={{ flex: 1, padding: '10px 14px', border: '1.5px solid #c8e6c9', borderRadius: '10px', fontSize: '15px', outline: 'none', backgroundColor: 'white' }}
          placeholder="이름 또는 이메일 검색"
          value={search}
          onChange={e => setSearch(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && fetchUsers()}
        />
        <button
          onClick={fetchUsers}
          style={{ backgroundColor: '#2d8a5e', color: 'white', border: 'none', borderRadius: '10px', padding: '10px 20px', fontSize: '15px', cursor: 'pointer', fontWeight: 600 }}
        >
          검색
        </button>
      </div>

      <p style={{ fontSize: '13px', color: '#666', marginBottom: '12px' }}>총 {users.length}명</p>

      {loading ? (
        <p style={{ color: '#2d8a5e', textAlign: 'center', padding: '2rem' }}>로딩 중...</p>
      ) : (
        <div style={{ backgroundColor: 'white', borderRadius: '14px', border: '1.5px solid #c8e6c9', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ backgroundColor: '#e8f5e9' }}>
                {['이름', '성별', '출생연도', '이메일', '가입일', ''].map(h => (
                  <th key={h} style={{ padding: '12px 16px', textAlign: 'left', fontSize: '13px', fontWeight: 600, color: '#2d8a5e' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {users.map((user, i) => (
                <tr key={user.id} style={{ borderTop: '1px solid #f0f0f0', backgroundColor: i % 2 === 0 ? 'white' : '#fafff8' }}>
                  <td style={{ padding: '12px 16px', fontSize: '14px' }}>{user.name ?? '-'}</td>
                  <td style={{ padding: '12px 16px', fontSize: '14px' }}>{user.gender ?? '-'}</td>
                  <td style={{ padding: '12px 16px', fontSize: '14px' }}>{user.birth_year ?? '-'}</td>
                  <td style={{ padding: '12px 16px', fontSize: '14px', color: '#555' }}>{user.users?.email ?? '-'}</td>
                  <td style={{ padding: '12px 16px', fontSize: '14px', color: '#555' }}>
                    {new Date(user.created_at).toLocaleDateString('ko-KR')}
                  </td>
                  <td style={{ padding: '12px 16px', display: 'flex', gap: '6px' }}>
                    <button onClick={() => setEditUser({ ...user })} style={btnStyle('#1565c0', '#e3f2fd', '#90caf9')}>수정</button>
                    <button onClick={() => handleDelete(user.id)} style={btnStyle('#d32f2f', '#fff0f0', '#ffcdd2')}>삭제</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      {/* 수정 모달 */}
      {editUser && (
        <div style={{ position: 'fixed', top: 0, left: 0, right: 0, bottom: 0, backgroundColor: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 1000 }}>
          <div style={{ backgroundColor: 'white', borderRadius: '16px', padding: '2rem', width: '440px', boxShadow: '0 8px 32px rgba(0,0,0,0.15)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.5rem' }}>
              <h2 style={{ fontSize: '18px', fontWeight: 700, color: '#2d8a5e' }}>유저 수정</h2>
              <button onClick={() => setEditUser(null)} style={{ background: 'none', border: 'none', fontSize: '20px', cursor: 'pointer', color: '#888' }}>✕</button>
            </div>

            {[
              { label: '이름', key: 'name' },
              { label: '성별', key: 'gender' },
              { label: '출생연도', key: 'birth_year' },
            ].map(f => (
              <div key={f.key} style={{ marginBottom: '12px' }}>
                <label style={{ fontSize: '13px', fontWeight: 600, color: '#2d8a5e', marginBottom: '4px', display: 'block' }}>{f.label}</label>
                <input
                  style={{ width: '100%', padding: '9px 12px', border: '1.5px solid #c8e6c9', borderRadius: '8px', fontSize: '14px', outline: 'none' }}
                  value={editUser[f.key] ?? ''}
                  onChange={e => setEditUser({ ...editUser, [f.key]: e.target.value })}
                />
              </div>
            ))}

            <div style={{ display: 'flex', gap: '8px', marginTop: '1.5rem', justifyContent: 'flex-end' }}>
              <button onClick={() => setEditUser(null)} style={{ padding: '10px 20px', borderRadius: '10px', border: '1.5px solid #c8e6c9', backgroundColor: 'white', color: '#2d8a5e', cursor: 'pointer', fontWeight: 600 }}>취소</button>
              <button onClick={handleUpdate} style={{ padding: '10px 20px', borderRadius: '10px', border: 'none', backgroundColor: '#2d8a5e', color: 'white', cursor: 'pointer', fontWeight: 600 }}>저장</button>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}