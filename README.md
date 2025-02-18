[![Go Report Card](https://goreportcard.com/badge/github.com/mergestat/fuse)](https://goreportcard.com/report/github.com/mergestat/fuse)
[![CI](https://github.com/mergestat/fuse/actions/workflows/ci.yaml/badge.svg)](https://github.com/mergestat/fuse/actions/workflows/ci.yaml)

# fuse

**experimental / beta**

MergeStat `fuse` is an experimental project to sync data from [`mergestat`](https://github.com/mergestat/mergestat) queries into PostgreSQL tables.
It behaves similar to an ETL tool, taking data from git repositories and the GitHub API and regularly updating tables in a database.
It's intended purpose is to enable "operational analytics for engineering teams," where downstream tools may consume the data from the PostgreSQL database.


## Roadmap

### Sync Types

- [x] `GITHUB_REPO_METADATA`
- [x] `GIT_COMMITS`
- [x] `GIT_COMMIT_STATS`
- [ ] `GIT_TAGS` ([#1](https://github.com/mergestat/fuse/issues/1))
- [ ] `GITHUB_REPO_PRS` ([#2](https://github.com/mergestat/fuse/issues/2))
- [ ] `GITHUB_REPO_ISSUES` ([#2](https://github.com/mergestat/fuse/issues/2))
- [ ] `GITHUB_REPO_STARS` ([#2](https://github.com/mergestat/fuse/issues/2))
