import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, addDoc, doc, updateDoc, deleteDoc, getDoc, query, orderBy, onSnapshot, increment, arrayUnion, arrayRemove, serverTimestamp } from 'firebase/firestore';

export default function ForumView() {
  // Get user info from URL params (similar to how other components work)
  const urlParams = new URLSearchParams(window.location.search);
  const userId = urlParams.get('userId');
  const role = urlParams.get('role');
  const email = urlParams.get('email');

  const [currentUser] = useState({ uid: userId, email });
  const [userData] = useState({ role, fullName: email?.split('@')[0] || '' });
  const [posts, setPosts] = useState([]);
  const [selectedPost, setSelectedPost] = useState(null);
  const [selectedPostComments, setSelectedPostComments] = useState([]);
  const [showCreateForm, setShowCreateForm] = useState(false);
  const [selectedTag, setSelectedTag] = useState('Tất cả');
  const [loading, setLoading] = useState(true);

  // Form states
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [newPostTag, setNewPostTag] = useState('Học tập');
  const [comment, setComment] = useState('');
  const [posting, setPosting] = useState(false);

  const tags = ['Tất cả', 'Học tập', 'Q&A', 'Sinh hoạt', 'Thông báo'];

  useEffect(() => {
    const q = query(collection(db, 'forum_posts'), orderBy('createdAt', 'desc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const postsData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setPosts(postsData);
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  useEffect(() => {
    if (!selectedPost) {
      setSelectedPostComments([]);
      return;
    }

    const q = query(collection(db, 'forum_posts', selectedPost.id, 'comments'), orderBy('createdAt', 'asc'));
    const unsubscribe = onSnapshot(q, (snapshot) => {
      const commentsData = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setSelectedPostComments(commentsData);
    });
    return () => unsubscribe();
  }, [selectedPost]);

  const filteredPosts = selectedTag === 'Tất cả'
    ? posts
    : posts.filter(post => post.tag === selectedTag);

  const handleCreatePost = async (e) => {
    e.preventDefault();
    if (!title.trim() || !content.trim()) return;

    setPosting(true);
    try {
      await addDoc(collection(db, 'forum_posts'), {
        title: title.trim(),
        content: content.trim(),
        tag: newPostTag,
        authorEmail: currentUser?.email || '',
        authorName: userData?.fullName || currentUser?.email?.split('@')[0] || '',
        authorRole: userData?.role || 'student',
        authorUid: currentUser?.uid || '',
        likes: [],
        commentCount: 0,
        createdAt: serverTimestamp(),
      });

      setTitle('');
      setContent('');
      setShowCreateForm(false);
    } catch (error) {
      console.error('Error creating post:', error);
    } finally {
      setPosting(false);
    }
  };

  const handleToggleLike = async (postId, likes) => {
    const postRef = doc(db, 'forum_posts', postId);
    if (likes.includes(currentUser?.uid)) {
      await updateDoc(postRef, { likes: arrayRemove(currentUser?.uid) });
    } else {
      await updateDoc(postRef, { likes: arrayUnion(currentUser?.uid) });
    }
  };

  const handleAddComment = async (e) => {
    e.preventDefault();
    if (!comment.trim() || !selectedPost) return;

    try {
      const commentsRef = collection(db, 'forum_posts', selectedPost.id, 'comments');
      await addDoc(commentsRef, {
        authorEmail: currentUser?.email || '',
        authorName: userData?.fullName || currentUser?.email?.split('@')[0] || '',
        authorRole: userData?.role || 'student',
        content: comment.trim(),
        createdAt: serverTimestamp(),
      });

      await updateDoc(doc(db, 'forum_posts', selectedPost.id), {
        commentCount: increment(1),
      });

      setComment('');
    } catch (error) {
      console.error('Error adding comment:', error);
    }
  };

  const getTagColor = (tag) => {
    const colors = {
      'Học tập': 'bg-blue-500/20 text-blue-400 border-blue-500/30',
      'Q&A': 'bg-orange-500/20 text-orange-400 border-orange-500/30',
      'Sinh hoạt': 'bg-green-500/20 text-green-400 border-green-500/30',
      'Thông báo': 'bg-purple-500/20 text-purple-400 border-purple-500/30',
    };
    return colors[tag] || 'bg-gray-500/20 text-gray-400 border-gray-500/30';
  };

  if (selectedPost) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 p-6">
        <div className="max-w-4xl mx-auto">
          <button
            onClick={() => setSelectedPost(null)}
            className="flex items-center gap-2 text-blue-400 hover:text-blue-300 mb-6"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
            </svg>
            Quay lại diễn đàn
          </button>

          <div className="bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700/50 p-8 mb-6">
            <div className="flex items-center gap-3 mb-4">
              <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${getTagColor(selectedPost.tag)}`}>
                {selectedPost.tag}
              </span>
              <span className="text-gray-400 text-sm">
                {selectedPost.createdAt?.toDate?.()?.toLocaleString('vi-VN') || ''}
              </span>
            </div>

            <h1 className="text-3xl font-bold text-white mb-4">{selectedPost.title}</h1>

            <div className="flex items-center gap-3 mb-6">
              <div className="w-10 h-10 rounded-full bg-blue-500/20 flex items-center justify-center">
                <span className="text-blue-400 font-bold">
                  {selectedPost.authorName?.[0]?.toUpperCase() || 'U'}
                </span>
              </div>
              <div>
                <p className="text-white font-semibold">{selectedPost.authorName}</p>
                <p className="text-gray-400 text-sm">
                  {selectedPost.authorRole === 'lecturer' ? 'Giảng viên' : 'Sinh viên'}
                </p>
              </div>
            </div>

            <div className="bg-gray-700/30 rounded-xl p-6 mb-6">
              <p className="text-gray-200 leading-relaxed whitespace-pre-wrap">{selectedPost.content}</p>
            </div>

            <button
              onClick={() => handleToggleLike(selectedPost.id, selectedPost.likes || [])}
              className={`flex items-center gap-2 px-4 py-2 rounded-full ${selectedPost.likes?.includes(currentUser?.uid)
                  ? 'bg-red-500/20 text-red-400 border border-red-500/30'
                  : 'bg-gray-700/30 text-gray-400 border border-gray-600/30'
                }`}
            >
              <svg className="w-5 h-5" fill={selectedPost.likes?.includes(currentUser?.uid) ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
              </svg>
              {selectedPost.likes?.length || 0} Thích
            </button>
          </div>

          <div className="bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700/50 p-8">
            <h2 className="text-xl font-bold text-white mb-6">Bình luận</h2>

            <form onSubmit={handleAddComment} className="mb-6">
              <div className="flex gap-4">
                <input
                  type="text"
                  value={comment}
                  onChange={(e) => setComment(e.target.value)}
                  placeholder="Viết bình luận..."
                  className="flex-1 bg-gray-700/30 border border-gray-600/30 rounded-xl px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-blue-500/50"
                />
                <button
                  type="submit"
                  className="bg-blue-500 hover:bg-blue-600 text-white px-6 py-3 rounded-xl font-semibold transition-colors"
                >
                  Gửi
                </button>
              </div>
            </form>

            <div className="space-y-4">
              {selectedPostComments.map((comment) => (
                <div key={comment.id} className="bg-gray-700/20 rounded-xl p-4 border-l-4 border-blue-500/50">
                  <div className="flex items-center gap-3 mb-2">
                    <span className="text-blue-400 font-semibold">{comment.authorName}</span>
                    <span className="text-gray-400 text-xs">
                      {comment.authorRole === 'lecturer' ? 'GV' : 'SV'}
                    </span>
                    <span className="text-gray-500 text-xs ml-auto">
                      {comment.createdAt?.toDate?.()?.toLocaleString('vi-VN') || ''}
                    </span>
                  </div>
                  <p className="text-gray-200">{comment.content}</p>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 p-6">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <svg className="w-8 h-8 text-blue-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
            </svg>
            <h1 className="text-2xl font-bold text-white">DIỄN ĐÀN HỌC TẬP</h1>
          </div>

          {!showCreateForm && (
            <button
              onClick={() => setShowCreateForm(true)}
              className="flex items-center gap-2 bg-blue-500 hover:bg-blue-600 text-white px-6 py-3 rounded-xl font-semibold transition-colors"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
              </svg>
              Tạo bài viết
            </button>
          )}
        </div>

        {!showCreateForm && (
          <div className="flex gap-3 mb-8 overflow-x-auto pb-2">
            {tags.map((tag) => (
              <button
                key={tag}
                onClick={() => setSelectedTag(tag)}
                className={`px-4 py-2 rounded-full text-sm font-semibold whitespace-nowrap transition-colors ${selectedTag === tag
                    ? 'bg-blue-500/20 text-blue-400 border border-blue-500/30'
                    : 'bg-gray-700/30 text-gray-400 border border-gray-600/30 hover:bg-gray-700/50'
                  }`}
              >
                {tag}
              </button>
            ))}
          </div>
        )}

        {showCreateForm ? (
          <div className="bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700/50 p-8">
            <button
              onClick={() => setShowCreateForm(false)}
              className="flex items-center gap-2 text-blue-400 hover:text-blue-300 mb-6"
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M10 19l-7-7m0 0l7-7m-7 7h18" />
              </svg>
              Hủy
            </button>

            <h2 className="text-xl font-bold text-white mb-6">Tạo bài viết mới</h2>

            <form onSubmit={handleCreatePost}>
              <div className="mb-4">
                <label className="block text-gray-300 text-sm mb-2">Chọn chủ đề:</label>
                <div className="flex flex-wrap gap-2">
                  {tags.filter(t => t !== 'Tất cả').map((tag) => (
                    <button
                      key={tag}
                      type="button"
                      onClick={() => setNewPostTag(tag)}
                      className={`px-4 py-2 rounded-full text-sm font-semibold ${newPostTag === tag
                          ? getTagColor(tag)
                          : 'bg-gray-700/30 text-gray-400 border border-gray-600/30'
                        }`}
                    >
                      {tag}
                    </button>
                  ))}
                </div>
              </div>

              <div className="mb-4">
                <input
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Tiêu đề bài viết"
                  className="w-full bg-gray-700/30 border border-gray-600/30 rounded-xl px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-blue-500/50"
                />
              </div>

              <div className="mb-6">
                <textarea
                  value={content}
                  onChange={(e) => setContent(e.target.value)}
                  placeholder="Nội dung bài viết..."
                  rows={8}
                  className="w-full bg-gray-700/30 border border-gray-600/30 rounded-xl px-4 py-3 text-white placeholder-gray-400 focus:outline-none focus:border-blue-500/50 resize-none"
                />
              </div>

              <button
                type="submit"
                disabled={posting}
                className="bg-blue-500 hover:bg-blue-600 disabled:bg-gray-600 text-white px-8 py-3 rounded-xl font-semibold transition-colors"
              >
                {posting ? 'Đang đăng...' : 'Đăng bài'}
              </button>
            </form>
          </div>
        ) : (
          <div className="space-y-4">
            {loading ? (
              <div className="text-center py-12">
                <div className="inline-block animate-spin rounded-full h-12 w-12 border-4 border-blue-500 border-t-transparent"></div>
              </div>
            ) : filteredPosts.length === 0 ? (
              <div className="text-center py-12">
                <svg className="w-16 h-16 text-gray-600 mx-auto mb-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z" />
                </svg>
                <p className="text-gray-400">Chưa có bài viết nào</p>
              </div>
            ) : (
              filteredPosts.map((post) => (
                <div
                  key={post.id}
                  onClick={() => setSelectedPost(post)}
                  className="bg-gray-800/50 backdrop-blur-sm rounded-2xl border border-gray-700/50 p-6 cursor-pointer hover:bg-gray-800/70 transition-colors"
                >
                  <div className="flex items-center gap-3 mb-4">
                    <span className={`px-3 py-1 rounded-full text-xs font-semibold border ${getTagColor(post.tag)}`}>
                      {post.tag}
                    </span>
                    <span className="px-2 py-1 rounded-full text-xs bg-gray-700/30 text-gray-400">
                      {post.authorRole === 'lecturer' ? 'Giảng viên' : 'Sinh viên'}
                    </span>
                    <span className="text-gray-400 text-xs ml-auto">
                      {post.createdAt?.toDate?.()?.toLocaleDateString('vi-VN') || ''}
                    </span>
                  </div>

                  <h3 className="text-lg font-bold text-white mb-2">{post.title}</h3>

                  <p className="text-gray-400 text-sm mb-4 line-clamp-2">
                    {post.content}
                  </p>

                  <div className="flex items-center justify-between">
                    <span className="text-blue-400 font-semibold text-sm">{post.authorName}</span>
                    <div className="flex items-center gap-4">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          handleToggleLike(post.id, post.likes || []);
                        }}
                        className="flex items-center gap-2 text-gray-400 hover:text-red-400 transition-colors"
                      >
                        <svg className="w-5 h-5" fill={post.likes?.includes(currentUser?.uid) ? 'currentColor' : 'none'} stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4.318 6.318a4.5 4.5 0 000 6.364L12 20.364l7.682-7.682a4.5 4.5 0 00-6.364-6.364L12 7.636l-1.318-1.318a4.5 4.5 0 00-6.364 0z" />
                        </svg>
                        {post.likes?.length || 0}
                      </button>
                      <div className="flex items-center gap-2 text-gray-400">
                        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
                        </svg>
                        {post.commentCount || 0}
                      </div>
                    </div>
                  </div>
                </div>
              ))
            )}
          </div>
        )}
      </div>
    </div>
  );
}
